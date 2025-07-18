# Terraform AWS Infrastructure

このプロジェクトは、TerraformとAWSを使用してクラウドインフラストラクチャをモジュール構成で管理します。

## 構成

- **VPC**: Virtual Private Cloud、パブリック・プライベートサブネット
- **S3**: オブジェクトストレージ

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
│   └── s3/                # S3モジュール
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

- `aws_region`: AWSリージョン (デフォルト: ap-northeast-1)
- `vpc_cidr`: VPCのCIDRブロック (デフォルト: 10.0.0.0/16)
- `s3_bucket_name`: S3バケット名
- `common_tags`: 共通タグ

### terraform.tfvarsファイルの作成

```bash
# terraform.tfvars
aws_region = "us-west-2"
vpc_cidr = "10.1.0.0/16"
s3_bucket_name = "my-unique-bucket-name"
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

- S3バケットはパブリックアクセスをブロック
- バージョニングとサーバーサイド暗号化を有効化
- セキュリティグループは最小限の権限で設定

## トラブルシューティング

### よくある問題

1. **S3バケット名の競合**
   - S3バケット名はグローバルで一意である必要があります
   - `s3_bucket_name`変数を変更してください

2. **AWS認証エラー**
   - AWS CLIが正しく設定されているか確認してください
   - `aws configure list`で設定を確認

3. **TFLintエラー**
   - `tflint --init`でプラグインを初期化してください

## 貢献

1. フォークしてブランチを作成
2. 変更を行い、`make quality`でテスト
3. プルリクエストを作成

## ライセンス

MIT License