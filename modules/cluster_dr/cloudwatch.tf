locals {
  route53_health_check_id = data.terraform_remote_state.route_53.outputs.onprem_health_check_id
}

# CloudWatch Metric Alarm - Route53 HealthCheck 기반 DR 트리거
resource "aws_cloudwatch_metric_alarm" "onprem_healthcheck" {
  provider            = aws.us_east_1
  alarm_name          = var.alarm_name
  alarm_description   = "온프레미스 Route53 HealthCheck 실패 시 DR Lambda를 호출합니다."
  comparison_operator = "LessThanThreshold"
  metric_name         = "HealthCheckPercentageHealthy"
  namespace           = "AWS/Route53"
  statistic           = "Average"
  period              = 60 # 1분 단위 평가
  evaluation_periods  = 2  # 2번 연속 헬스 체크 실패할 경우
  threshold           = 99 # 평균 성공률이 99% 미만이면 ALARM 생성

  dimensions = {
    HealthCheckId = local.route53_health_check_id
  }

  # ALARM 상태 진입 시 SNS 알림
  alarm_actions = [aws_sns_topic.dr_notification.arn]

  # 데이터 없을 때도 장애로 간주
  treat_missing_data = "breaching"

  tags = {
    Project = "team"
  }
}
