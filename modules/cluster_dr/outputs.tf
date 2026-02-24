output "lambda_function_arn" {
  description = "DR 자동화 Lambda 함수 ARN"
  value       = aws_lambda_function.dr_scaler.arn
}

output "lambda_function_name" {
  description = "DR 자동화 Lambda 함수 이름"
  value       = aws_lambda_function.dr_scaler.function_name
}

output "cloudwatch_alarm_arn" {
  description = "Route53 HealthCheck 기반 CloudWatch Alarm ARN"
  value       = aws_cloudwatch_metric_alarm.onprem_healthcheck.arn
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch Alarm 이름"
  value       = aws_cloudwatch_metric_alarm.onprem_healthcheck.alarm_name
}
