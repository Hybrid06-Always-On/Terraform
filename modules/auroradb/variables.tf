variable "vpc_id" {
  description = "VPC ID"
  type        = string
}


variable "db_username" {
  description = "Master 사용자 이름 (root 제외)"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master 비밀번호"
  type        = string
  sensitive   = true
}

