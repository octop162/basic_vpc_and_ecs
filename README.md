# Terraform AWS Infrastructure

このプロジェクトは、TerraformとAWSを使用してクラウドインフラストラクチャをモジュール構成で管理します。

## 構成

- **VPC**: Virtual Private Cloud、パブリック・プライベートサブネット、NATゲートウェイ
- **ALB + ECS**: Application Load Balancer + ECS Fargate（Blue/Green デプロイメント対応）

## ディレクトリ構造

```
.
├── main.tf                 # メインの設定ファイル
├── variables.tf            # 変数定義
├── outputs.tf              # 出力値定義
├── modules/
│   ├── vpc/               # VPCモジュール
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── web/               # ALB + ECS モジュール
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── .tflint.hcl            # TFLint設定
├── .pre-commit-config.yaml # pre-commitフック設定
├── .gitignore             # Git除外設定
└── Makefile               # 開発用コマンド集
```

## 前提条件

- Terraform >= 1.0
- AWS CLI設定済み
- TFLint (推奨)
- pre-commit (推奨)

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

### 3. 開発ツールのインストール (推奨)

```bash
# TFLintのインストール
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# pre-commitのインストール
pip install pre-commit
pre-commit install
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

## 設定のカスタマイズ

### 変数の変更

`variables.tf`で以下の設定を変更できます：

#### VPC設定
- `tokyo_vpc_cidr`: 東京リージョンVPCのCIDRブロック (デフォルト: 10.0.0.0/16)
- `tokyo_availability_zones`: 使用するアベイラビリティゾーン
- `tokyo_public_subnet_cidrs`: パブリックサブネットのCIDRブロック
- `tokyo_private_subnet_cidrs`: プライベートサブネットのCIDRブロック

#### Web設定
- `container_image`: ECSで使用するコンテナイメージ (デフォルト: nginx:latest)
- `container_port`: コンテナポート (デフォルト: 80)
- `desired_count`: ECSタスク数 (デフォルト: 2)

#### 共通設定
- `common_tags`: 共通タグ

### terraform.tfvarsファイルの作成

```bash
# terraform.tfvars
tokyo_vpc_cidr = "10.1.0.0/16"
tokyo_public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
tokyo_private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24"]
common_tags = {
  Environment = "production"
  Project     = "my-project"
  ManagedBy   = "terraform"
}
```

## Makefileコマンド

| コマンド | 説明 |
|---------|------|
| `make init` | Terraform初期化 |
| `make plan` | 実行計画の表示 |
| `make apply` | インフラストラクチャの作成 |
| `make destroy` | インフラストラクチャの削除 |
| `make fmt` | コードフォーマット |
| `make validate` | Terraform設定の検証 |
| `make lint` | TFLintでコード検査 |
| `make security` | tfsecでセキュリティスキャン |
| `make quality` | 全品質チェック |
| `make dev` | 開発ワークフロー |
| `make clean` | 一時ファイルの削除 |

## セキュリティ

- セキュリティグループは最小限の権限で設定
- ECSタスクはプライベートサブネットで実行
- ALBは必要なポート（80, 20080）のみ開放

## トラブルシューティング

### よくある問題

1. **AWS認証エラー**
   - AWS CLIが正しく設定されているか確認してください
   - `aws configure list`で設定を確認

2. **TFLintエラー**
   - `tflint --init`でプラグインを初期化してください

3. **ECSタスクが起動しない**
   - CloudWatch Logsで詳細なエラーログを確認してください
   - セキュリティグループの設定を確認してください

4. **Blue/Green デプロイメント**
   - メインリスナー（80番ポート）: 本番環境へのアクセス
   - テストリスナー（20080番ポート）: 新バージョンのテスト用

## 貢献

1. フォークしてブランチを作成
2. 変更を行い、`make quality`でテスト
3. プルリクエストを作成
