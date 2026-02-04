variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
}

variable "db_username" {
  description = "Database Master Username"
  type        = string
}

variable "db_password" {
  description = "Database Master Password"
  type        = string
  sensitive   = true
}
