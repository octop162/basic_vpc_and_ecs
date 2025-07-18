# Tokyo Region Variables
variable "tokyo_vpc_cidr" {
  description = "CIDR block for Tokyo VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tokyo_availability_zones" {
  description = "List of availability zones in Tokyo"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "tokyo_public_subnet_cidrs" {
  description = "CIDR blocks for Tokyo public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "tokyo_private_subnet_cidrs" {
  description = "CIDR blocks for Tokyo private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Osaka Region Variables
variable "osaka_vpc_cidr" {
  description = "CIDR block for Osaka VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "osaka_availability_zones" {
  description = "List of availability zones in Osaka"
  type        = list(string)
  default     = ["ap-northeast-3a", "ap-northeast-3c"]
}

variable "osaka_public_subnet_cidrs" {
  description = "CIDR blocks for Osaka public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "osaka_private_subnet_cidrs" {
  description = "CIDR blocks for Osaka private subnets"
  type        = list(string)
  default     = ["10.1.101.0/24", "10.1.102.0/24"]
}


variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-aws"
    ManagedBy   = "terraform"
  }
}