# Terraform AWS Infrastructure

このプロジェクトは、TerraformとAWSを使用してBlue-Greenデプロイメント対応のクラウドインフラストラクチャをモジュール構成で管理します。

## 構成

- **VPC**: Virtual Private Cloud、パブリック・プライベートサブネット、NATゲートウェイ
- **ALB**: Application Load Balancer（Web用、API用）
- **ECS**: ECS Fargate with Blue-Greenデプロイメント
- **Lambda**: ECSデプロイメントフック

## ディレクトリ構造

```
.
├── main.tf                 # メインの設定ファイル
├── variables.tf            # 変数定義
├── modules/
│   ├── vpc/               # VPCモジュール
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/               # ALBモジュール
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs/               # ECSモジュール（配列対応ALB設定）
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecs_hook/          # ECSデプロイメントフック
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── src.zip
│       └── src/
│           └── index.py
├── .tflint.hcl            # TFLint設定
├── .pre-commit-config.yaml # pre-commitフック設定
├── .gitignore             # Git除外設定
├── CLAUDE.md              # Claude設定ファイル
└── Makefile               # 開発用コマンド集
```

## セットアップ

### 1. AWS認証情報の設定

```bash
aws configure
```

### 2. Terraform初期化

```bash
terraform init
# または
make init
```

## 使用方法

### 基本的なワークフロー

```bash
# 1. 初期化
make init

# 2. フォーマット
make fmt

# 3. 検証とLint
make validate
make lint

# 4. 実行計画の確認
make plan

# 5. インフラストラクチャのデプロイ
make apply

# 6. インフラストラクチャの削除
make destroy
```

### 開発ワークフロー

```bash
# 開発用の一連のコマンドを実行
make dev
```

### 品質チェック

```bash
# 全品質チェック（format, validate, lint, security）
make quality
```

## アーキテクチャ詳細

### ECSモジュールの特徴

- **複数ALB対応**: `alb_configs`配列を使用して複数のALBからのトラフィックを受信可能
- **Blue-Greenデプロイメント**: AWS ECS Blue-Greenデプロイメント戦略を使用
- **ライフサイクルフック**: Lambdaフックによるデプロイメント後処理

### ALB設定例

```hcl
alb_configs = [
  {
    alb_security_group_id  = module.web_alb_tokyo.alb_security_group_id
    blue_target_group_arn  = module.web_alb_tokyo.blue_target_group_arn
    green_target_group_arn = module.web_alb_tokyo.green_target_group_arn
    main_listener_arn      = module.web_alb_tokyo.main_listener_arn
    main_listener_rule_arn = module.web_alb_tokyo.main_listener_rule_arn
    test_listener_rule_arn = module.web_alb_tokyo.test_listener_rule_arn
  },
  {
    alb_security_group_id  = module.api_alb_tokyo.alb_security_group_id
    blue_target_group_arn  = module.api_alb_tokyo.blue_target_group_arn
    green_target_group_arn = module.api_alb_tokyo.green_target_group_arn
    main_listener_arn      = module.api_alb_tokyo.main_listener_arn
    main_listener_rule_arn = module.api_alb_tokyo.main_listener_rule_arn
    test_listener_rule_arn = module.api_alb_tokyo.test_listener_rule_arn
  }
]
```

## デプロイメント戦略

1. **初回デプロイ**: Blueスロットにアプリケーションをデプロイ
2. **更新デプロイ**: Greenスロットに新バージョンをデプロイし、段階的にトラフィックを切り替え
3. **ライフサイクルフック**: デプロイメント完了後にLambda関数が実行され、後処理を実行