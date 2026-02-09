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

variable "instance_count" {
  type        = number
  description = "생성할 Aurora 인스턴스 개수 (1이면 Writer만, 2이상이면 Reader 추가)"
  default     = 1
}
