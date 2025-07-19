terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
  }
}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

module "vpc_tokyo" {
  source = "./modules/vpc"

  providers = {
    aws = aws.tokyo
  }

  vpc_cidr             = var.tokyo_vpc_cidr
  availability_zones   = var.tokyo_availability_zones
  public_subnet_cidrs  = var.tokyo_public_subnet_cidrs
  private_subnet_cidrs = var.tokyo_private_subnet_cidrs

  tags = merge(var.common_tags, {
    Region = "ap-northeast-1"
  })
}

module "ecs_hook_tokyo" {
  source = "./modules/ecs_hook"

  providers = {
    aws = aws.tokyo
  }

  tags = merge(var.common_tags, {
    Region = "ap-northeast-1"
  })
}

module "web_alb_tokyo" {
  source = "./modules/alb"

  providers = {
    aws = aws.tokyo
  }

  name              = "web"
  vpc_id            = module.vpc_tokyo.vpc_id
  public_subnet_ids = module.vpc_tokyo.public_subnet_ids
  container_port    = var.container_port

  tags = merge(var.common_tags, {
    Region = "ap-northeast-1"
  })
}

module "api_alb_tokyo" {
  source = "./modules/alb"

  providers = {
    aws = aws.tokyo
  }

  name              = "web-admin"
  vpc_id            = module.vpc_tokyo.vpc_id
  public_subnet_ids = module.vpc_tokyo.public_subnet_ids
  container_port    = var.container_port

  tags = merge(var.common_tags, {
    Region = "ap-northeast-1"
  })
}

module "web_ecs_tokyo" {
  source = "./modules/ecs"

  providers = {
    aws = aws.tokyo
  }

  name                   = "web"
  vpc_id                 = module.vpc_tokyo.vpc_id
  private_subnet_ids     = module.vpc_tokyo.private_subnet_ids

  container_image        = var.container_image
  container_port         = var.container_port
  desired_count          = var.desired_count

  lambda_function_arn    = module.ecs_hook_tokyo.lambda_function_arn

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

  tags = merge(var.common_tags, {
    Region = "ap-northeast-1"
  })
}
