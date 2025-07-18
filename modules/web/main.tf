terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
  }
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "web-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 20080
    to_port     = 20080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "web-alb-sg"
  })
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs" {
  name        = "web-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "web-ecs-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "web-alb"
  })
}

# ALB Target Group - Blue
resource "aws_lb_target_group" "blue" {
  name        = "web-tg-blue"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name = "web-tg-blue"
  })
}

# ALB Target Group - Green
resource "aws_lb_target_group" "green" {
  name        = "web-tg-green"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name = "web-tg-green"
  })
}

# ALB Listener - Production
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  lifecycle {
    ignore_changes = [default_action[0].forward[0].target_group]
  }
}

# Test Listener for Blue/Green deployment
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = "20080"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  lifecycle {
    ignore_changes = [default_action[0].forward[0].target_group]
  }
}

# Listener Rule for Main Listener
resource "aws_lb_listener_rule" "main_default" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  lifecycle {
    ignore_changes = [action[0].forward[0].target_group]
  }
}

# Listener Rule for Test Listener
resource "aws_lb_listener_rule" "test_default" {
  listener_arn = aws_lb_listener.test.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  lifecycle {
    ignore_changes = [action[0].forward[0].target_group]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "web-cluster"

  tags = merge(var.tags, {
    Name = "web-cluster"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "web-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "web"
      image = var.container_image

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = data.aws_region.current.id
          awslogs-stream-prefix = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = merge(var.tags, {
    Name = "web-task"
  })
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "web"
    container_port   = var.container_port
    advanced_configuration {
      alternate_target_group_arn = aws_lb_target_group.green.arn
      production_listener_rule = aws_lb_listener_rule.main_default.arn
      test_listener_rule = aws_lb_listener_rule.test_default.arn
      role_arn = aws_iam_role.ecs_deployment_role.arn
    }
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_configuration {
    strategy = "BLUE_GREEN"
    bake_time_in_minutes = 0
    lifecycle_hook {
      hook_target_arn = aws_lambda_function.ecs_service_hook.arn
      role_arn = aws_iam_role.ecs_deployment_role.arn
      lifecycle_stages = ["POST_TEST_TRAFFIC_SHIFT"]
    }
  }

  depends_on = [aws_lb_listener.main]

  tags = merge(var.tags, {
    Name = "web-service"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/web"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "web-ecs-logs"
  })
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "web-ecs-execution-role"

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
    Name = "web-ecs-execution-role"
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
  name = "web-ecs-deployment-role"
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
    Name = "web-ecs-deployment-role"
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
        Resource = aws_lambda_function.ecs_service_hook.arn
      }
    ]
  })
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

# Lambda Hook for ECS Service Deployment
resource "aws_lambda_function" "ecs_service_hook" {
  function_name = "ecs_service_hook"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.10"
  filename      = "${data.archive_file.lambda_function.output_path}"
  source_code_hash = filebase64sha256("${data.archive_file.lambda_function.output_path}")
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

