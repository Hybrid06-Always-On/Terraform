output "onprem_health_check_id" {
  description = "The ID of the Route 53 health check for on-premises"
  value       = aws_route53_health_check.onprem.id
}
