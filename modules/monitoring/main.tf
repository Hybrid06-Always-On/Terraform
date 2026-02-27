# 1. 이름이 "team_node_group"인 인스턴스
data "aws_instances" "team_nodes" {
  instance_tags = {
    Name = "team_node_group"
  }
  instance_state_names = ["running"]
}

# 2. 찾은 인스턴스 개수만큼 CPU 알람을 자동으로 생성합니다.
resource "aws_cloudwatch_metric_alarm" "cpu_high_alert" {
  for_each = toset(data.aws_instances.team_nodes.ids)

  alarm_name          = "EC2-High-CPU-${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "인스턴스 ${each.value}의 CPU가 10분간 90%를 넘었습니다."
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:260028436792:team-slack-alert-topic"]

  dimensions = {
    InstanceId = each.value # 반복되는 각 인스턴스 ID를 자동으로 주입
  }
}

# 3. 서버 장애 알림 (Status Check)도 똑같이 반복 생성
resource "aws_cloudwatch_metric_alarm" "instance_status_failure" {
  for_each = toset(data.aws_instances.team_nodes.ids)

  alarm_name          = "EC2-Status-Check-Failed-${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_actions       = ["arn:aws:sns:ap-northeast-2:260028436792:team-slack-alert-topic"]

  dimensions = {
    InstanceId = each.value
  }
}

# 4. 상태 변경 알림
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name = "EC2-State-Change-Rule"
  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["EC2 Instance State-change Notification"],
    "detail" : {
      "state" : ["stopping", "stopped", "shutting-down", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule = aws_cloudwatch_event_rule.ec2_state_change.name
  arn  = "arn:aws:sns:ap-northeast-2:260028436792:team-slack-alert-topic"
}
