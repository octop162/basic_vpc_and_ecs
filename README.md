# Terraform AWS Infrastructure

このプロジェクトは、TerraformとAWSを使用してクラウドインフラストラクチャをモジュール構成で管理します。

## 構成

- **VPC**: Virtual Private Cloud、パブリック・プライベートサブネット、NATゲートウェイ
- **ALB + ECS**: Application Load Balancer + ECS Fargate

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