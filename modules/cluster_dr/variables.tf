# VPC 변수 ### 
variable "team_vpc_id" {
  description = "VPC ID"
  type        = string
}

## EKS Cluster 변수 ###
variable "team_cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "team_cluster_endpoint" {
  description = "EKS API 서버 엔드포인트"
  type        = string
}

### Lambda 변수 ###
variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "alarm_name" {
  description = "CloudWatch Alarm 이름"
  type        = string
  default     = "onprem-healthcheck-alarm"
}

variable "lambda_function_name" {
  description = "DR 자동화 Lambda 함수 이름"
  type        = string
  default     = "dr-eks-scaler"
}

variable "team_prisn_ids" {
  description = "The private subnet IDs from the network module"
  type        = list(string)
}

variable "scale_replicas" {
  description = "DR 활성화 시 EKS Deployment replica 수"
  type        = number
  default     = 3
}

variable "app_namespace" {
  description = "WEB/WAS Deployment가 배포된 네임스페이스"
  type        = string
  default     = "app"
}

variable "web_hpa_name" {
  description = "WEB HPA 이름"
  type        = string
  default     = "frontend-hpa"
}

variable "was_hpa_name" {
  description = "WAS HPA 이름"
  type        = string
  default     = "backend-hpa"
}

### 온프레미스 헬스 체크 변수 ###
# DB host/port/dbname/username/password 모두 Secrets Manager에 저장
variable "onprem_db_secret_arn" {
  description = "온프레미스 DB 접속 정보"
  type        = string
  default     = "arn:aws:secretsmanager:ap-northeast-2:260028436792:secret:onprem_db-n5gmxv"
}

variable "onprem_minio_endpoint" {
  description = "온프레미스 MinIO 엔드포인트"
  type        = string
  default     = "http://10.5.1.20:9000"
}

variable "onprem_minio_bucket" {
  description = "MinIO 헬스 체크용 버킷 이름"
  type        = string
  default     = "video-thumb"
}

variable "onprem_minio_secret_arn" {
  description = "MinIO ACCESS_KEY/SECRET_KEY"
  type        = string
  default     = "arn:aws:secretsmanager:ap-northeast-2:260028436792:secret:onprem_minio-o0tBgT"
}

variable "onprem_api_url" {
  description = "온프레미스 헬스체크 API URL"
  type        = string
  default     = "https://alwaysonteam.store/api/thumbnails/1"
}

variable "onprem_api_timeout_sec" {
  description = "API 헬스체크 타임아웃 (ms)"
  type        = number
  default     = 5
}

variable "onprem_api_warn_ms" {
  description = "API 응답시간 경고 기준 (ms)"
  type        = number
  default     = 2000
}

variable "health_fail_threshold" {
  description = "DR 발동 기준 설정 : 3개 헬스체크 중 2개 이상 실패 시 EKS scale-up"
  type        = number
  default     = 2
}

# Slack Webhook URL ARN
variable "slack_webhook_url_arn" {
  description = "Slack Webhook URL ARN"
  type        = string
  default     = "arn:aws:secretsmanager:ap-northeast-2:260028436792:secret:slack_webhook-zqnwAh"
}
