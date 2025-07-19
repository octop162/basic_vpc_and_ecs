variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for minimal ECS network configuration"
  type        = list(string)
}

# Most variables removed as ecspresso will manage ECS configuration

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}