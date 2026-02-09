variable "db_username" {
  description = "Database Master Username"
  type        = string
}

variable "db_password" {
  description = "Database Master Password"
  type        = string
  sensitive   = true
}

variable "instance_count" {
  type        = number
  description = "생성할 Aurora 인스턴스 개수 (1이면 Writer만, 2이상이면 Reader 추가)"
  default     = 1
}
