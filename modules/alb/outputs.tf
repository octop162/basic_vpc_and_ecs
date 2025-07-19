output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "blue_target_group_arn" {
  description = "Blue target group ARN"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "Green target group ARN"
  value       = aws_lb_target_group.green.arn
}

output "main_listener_arn" {
  description = "Main listener ARN"
  value       = aws_lb_listener.main.arn
}

output "test_listener_arn" {
  description = "Test listener ARN"
  value       = aws_lb_listener.test.arn
}

output "main_listener_rule_arn" {
  description = "Main listener rule ARN"
  value       = aws_lb_listener_rule.main_default.arn
}

output "test_listener_rule_arn" {
  description = "Test listener rule ARN"
  value       = aws_lb_listener_rule.test_default.arn
}