terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

module "web_tokyo" {
  source = "./modules/web"

  providers = {
    aws = aws.tokyo
  }

  vpc_id             = module.vpc_tokyo.vpc_id
  public_subnet_ids  = module.vpc_tokyo.public_subnet_ids
  private_subnet_ids = module.vpc_tokyo.private_subnet_ids

  tags = merge(var.common_tags, {
    Region = "ap-northeast-1"
  })
}
