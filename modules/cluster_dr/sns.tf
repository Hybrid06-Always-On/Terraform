# # SNS 토픽 생성 
resource "aws_sns_topic" "dr_notification" {
  provider = aws.us_east_1
  name     = "onprem-dr-notification"
}

# Lambda 구독 설정 
resource "aws_sns_topic_subscription" "dr_lambda_subscription" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.dr_notification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.dr_scaler.arn
}

