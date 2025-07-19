variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# Most variables removed as ecspresso will manage ECS configuration

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}