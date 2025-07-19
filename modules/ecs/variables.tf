variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_configs" {
  description = "List of ALB configurations"
  type = list(object({
    alb_security_group_id  = string
    blue_target_group_arn  = string
    green_target_group_arn = string
    main_listener_arn      = string
    main_listener_rule_arn = string
    test_listener_rule_arn = string
  }))
}

variable "lambda_function_arn" {
  description = "Lambda function ARN for deployment hooks"
  type        = string
}

variable "container_image" {
  description = "Container image for ECS task"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}