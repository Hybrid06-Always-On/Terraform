# variable "cluster_identifier" {
#   description = "Aurora Cluster ID"
#   type        = string
# }

# variable "cluster_name" {
#   description = "EKS Cluster Name"
#   type        = string
# }

# 아직 미완성인 리소스들 (기본값을 null로 설정)
variable "vpn_connection_id" {
  description = "VPN ID (미완성 시 null 가능)"
  type        = string
  default     = null
}

variable "cloudfront_id" {
  description = "CloudFront ID (미완성 시 null 가능)"
  type        = string
  default     = null
}

variable "sns_topic_name" {
  default = "dr-slack-alarm-topic"
}

