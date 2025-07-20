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

# Lambda Hook for ECS Service Deployment
resource "aws_lambda_function" "ecs_service_hook" {
  function_name    = "ecs_service_hook"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.10"
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_function.output_path)
  environment {
    variables = {
      TZ = "Asia/Tokyo"
    }
  }
  tags = merge(var.tags, {
    Name = "ecs-service-hook"
  })
}

# Zip the Lambda function code
data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/src/index.py"
  output_path = "${path.module}/src.zip"
}