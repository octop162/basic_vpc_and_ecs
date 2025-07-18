# Tokyo Region Outputs
output "tokyo_vpc_id" {
  description = "Tokyo VPC ID"
  value       = module.vpc_tokyo.vpc_id
}

output "tokyo_public_subnet_ids" {
  description = "Tokyo public subnet IDs"
  value       = module.vpc_tokyo.public_subnet_ids
}

output "tokyo_private_subnet_ids" {
  description = "Tokyo private subnet IDs"
  value       = module.vpc_tokyo.private_subnet_ids
}

# Web Application Outputs
output "tokyo_alb_dns_name" {
  description = "Tokyo ALB DNS name"
  value       = module.web_tokyo.alb_dns_name
}

output "tokyo_alb_arn" {
  description = "Tokyo ALB ARN"
  value       = module.web_tokyo.alb_arn
}

output "tokyo_ecs_cluster_name" {
  description = "Tokyo ECS cluster name"
  value       = module.web_tokyo.ecs_cluster_name
}

output "tokyo_ecs_service_name" {
  description = "Tokyo ECS service name"
  value       = module.web_tokyo.ecs_service_name
}