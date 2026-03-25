# GitHub Actions セットアップ手順

GitHub Actions から AWS リソースへアクセスするための OIDC 連携・IAM ロール・S3 バックエンドの設定手順。

## 前提

- AWS CLI が設定済み
- GitHub リポジトリ: `octop162/basic_vpc_and_ecs`
- AWS アカウント ID: 対象アカウント
- リージョン: `ap-northeast-1`

## 1. S3 バケット作成（tfstate 用）

```bash
# バケット作成
aws s3api create-bucket \
  --bucket octop162-terraform-state \
  --region ap-northeast-1 \
  --create-bucket-configuration LocationConstraint=ap-northeast-1

# バージョニング有効化
aws s3api put-bucket-versioning \
  --bucket octop162-terraform-state \
  --versioning-configuration Status=Enabled

# パブリックアクセスブロック
aws s3api put-public-access-block \
  --bucket octop162-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

## 2. OIDC プロバイダー作成

AWS アカウントで1回だけ実行。既に存在する場合はスキップ。

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## 3. IAM ロール作成

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam create-role \
  --role-name github-actions-deploy \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Principal\": {
          \"Federated\": \"arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com\"
        },
        \"Action\": \"sts:AssumeRoleWithWebIdentity\",
        \"Condition\": {
          \"StringEquals\": {
            \"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\"
          },
          \"StringLike\": {
            \"token.actions.githubusercontent.com:sub\": \"repo:octop162/basic_vpc_and_ecs:*\"
          }
        }
      }
    ]
  }"
```

## 4. IAM ポリシーアタッチ

```bash
# ECR（イメージ push）
aws iam attach-role-policy \
  --role-name github-actions-deploy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# ECS（デプロイ）
aws iam attach-role-policy \
  --role-name github-actions-deploy \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# SSM + S3（デプロイ承認 + tfstate 読み取り）
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam put-role-policy \
  --role-name github-actions-deploy \
  --policy-name deploy-extras \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Action\": [
          \"ssm:PutParameter\",
          \"ssm:GetParameter\",
          \"ssm:DeleteParameter\"
        ],
        \"Resource\": \"arn:aws:ssm:ap-northeast-1:${ACCOUNT_ID}:parameter/ecs-deploy/*\"
      },
      {
        \"Effect\": \"Allow\",
        \"Action\": \"s3:GetObject\",
        \"Resource\": \"arn:aws:s3:::octop162-terraform-state/*\"
      }
    ]
  }"
```

# iam:PassRole（ECS デプロイ時に deployment/execution ロールを渡すため）
aws iam put-role-policy \
  --role-name github-actions-deploy \
  --policy-name ecs-pass-role \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Action\": \"iam:PassRole\",
        \"Resource\": [
          \"arn:aws:iam::${ACCOUNT_ID}:role/web-ecs-deployment-role\",
          \"arn:aws:iam::${ACCOUNT_ID}:role/web-ecs-execution-role\"
        ]
      }
    ]
  }"
```

## 5. GitHub リポジトリ設定

### Secrets

**Settings > Secrets and variables > Actions > New repository secret**

| Secret 名 | 値 |
|-----------|-----|
| `AWS_ROLE_ARN` | `arn:aws:iam::<ACCOUNT_ID>:role/github-actions-deploy` |

### Environment

**Settings > Environments > New environment**

1. 名前: `production`
2. "Required reviewers" にチェック
3. 承認者を追加

これにより `approve` ジョブ実行時にレビュアーの手動承認が必要になる。

## 確認

ロールの信頼ポリシー確認:

```bash
aws iam get-role --role-name github-actions-deploy \
  --query 'Role.AssumeRolePolicyDocument' --output json
```

アタッチ済みポリシー確認:

```bash
aws iam list-attached-role-policies --role-name github-actions-deploy
aws iam list-role-policies --role-name github-actions-deploy
```
