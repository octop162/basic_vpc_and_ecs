output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.ecs_service_hook.arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.ecs_service_hook.function_name
}