terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Lambda Role
resource "aws_iam_role" "lambda_role" {
  name = "web-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "web-lambda-role"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "ssm_access" {
  name        = "EcsHookSSMAccessPolicy"
  description = "Policy to allow Lambda function to access SSM Parameter Store for deploy state"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DeleteParameter"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/ecs-deploy/*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "ecs-hook-ssm-access-policy"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

# Lambda Hook for ECS Service Deployment
resource "aws_lambda_function" "ecs_service_hook" {
  function_name    = "ecs_service_hook"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_function.output_path)
  environment {
    variables = {
      TZ                = "Asia/Tokyo"
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
  tags = merge(var.tags, {
    Name = "ecs-service-hook"
  })
}

# Zip the Lambda function code
data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}
