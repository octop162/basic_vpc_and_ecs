terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
  }
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Allow from VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-ecs-sg"
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster"

  tags = merge(var.tags, {
    Name = "${var.name}-cluster"
  })
}

# Minimal ECS Task Definition for ecspresso management
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  # Minimal container definition - ecspresso will override
  container_definitions = jsonencode([
    {
      name      = var.name
      image     = "nginx:latest"
      essential = true
    }
  ])

  lifecycle {
    ignore_changes = [
      container_definitions,
      cpu,
      memory
    ]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-task"
  })
}

# Minimal ECS Service for ecspresso management
resource "aws_ecs_service" "main" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 0  # ecspresso will manage this

  # Minimal network configuration required for awsvpc mode
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
  }
  launch_type      = "FARGATE"

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
      load_balancer,
      deployment_configuration,
      network_configuration,
      deployment_circuit_breaker,
      deployment_minimum_healthy_percent,
      deployment_maximum_percent,
      health_check_grace_period_seconds,
      tags,
      tags_all
    ]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-service"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.name}-ecs-logs"
  })
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-ecs-execution-role"
  })
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Data source for current AWS region
data "aws_region" "current" {}


# IAM Role for ECS Deployment
resource "aws_iam_role" "ecs_deployment_role" {
  name = "${var.name}-ecs-deployment-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      }
    ]
  })
  tags = merge(var.tags, {
    Name = "${var.name}-ecs-deployment-role"
  })
}

# IAM Role Policy Attachment for ECS Service
resource "aws_iam_role_policy_attachment" "ecs_service_role_policy" {
  role       = aws_iam_role.ecs_deployment_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# IAM Role Policy Attachment for ELB Full Access
resource "aws_iam_role_policy_attachment" "elb_full_access_policy" {
  role       = aws_iam_role.ecs_deployment_role.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# IAM Role Inline Policy for Lambda Invoke
resource "aws_iam_role_policy" "lambda_invoke_policy" {
  name = "lambda-invoke-policy"
  role = aws_iam_role.ecs_deployment_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"  # ecspresso will determine the specific Lambda
      }
    ]
  })
}