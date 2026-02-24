# Lambda 소스 코드 zip 패키징
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/scale_eks.zip"
}

# DR 자동화 Lambda 함수
resource "aws_lambda_function" "dr_scaler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_dr_role.arn
  handler          = "scale_eks.lambda_handler"
  runtime          = "python3.12"
  timeout          = 300 # EKS API 호출 여유시간 5분
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      # 한국 시간대 타임존 설정
      TZ = "Asia/Seoul"

      # EKS 접근 정보
      CLUSTER_NAME     = var.team_cluster_name
      CLUSTER_ENDPOINT = var.team_cluster_endpoint
      REGION           = var.region
      SCALE_REPLICAS   = tostring(var.scale_replicas)
      APP_NAMESPACE    = var.app_namespace
      WEB_HPA          = var.web_hpa_name
      WAS_HPA          = var.was_hpa_name

      # 온프레미스 DB 헬스체크 
      ONPREM_DB_SECRET_ARN = var.onprem_db_secret_arn

      # 온프레미스 MinIO 헬스체크 
      ONPREM_MINIO_ENDPOINT   = var.onprem_minio_endpoint
      ONPREM_MINIO_BUCKET     = var.onprem_minio_bucket
      ONPREM_MINIO_SECRET_ARN = var.onprem_minio_secret_arn

      # 온프레미스 API 헬스체크
      ONPREM_API_URL         = var.onprem_api_url
      ONPREM_API_TIMEOUT_SEC = tostring(var.onprem_api_timeout_sec)
      ONPREM_API_WARN_MS     = tostring(var.onprem_api_warn_ms)

      # DR 발동 임계값
      HEALTH_FAIL_THRESHOLD = tostring(var.health_fail_threshold)

      # Slack 웹훅 URL
      SLACK_WEBHOOK_URL = var.slack_webhook_url_arn
    }
  }

  # VPC 지정
  vpc_config {
    subnet_ids         = var.team_prisn_ids
    security_group_ids = [aws_security_group.lambda_dr_sg.id]
  }

  tags = {
    Project = "team"
    Purpose = "DR automation - EKS scale-up"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_execution,
    aws_iam_role_policy.lambda_secrets_policy,
  ]
}

# CloudWatch Alarms가 Lambda를 직접 호출할 수 있도록 허용
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_scaler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.dr_notification.arn
}
