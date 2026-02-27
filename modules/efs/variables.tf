variable "efs_name" {
  description = "EFS 파일 시스템의 이름 태그"
  type        = string
  default     = "team-efs-filesystem"
}

variable "efs_performance_mode" {
  description = "EFS 성능 모드 (generalPurpose 또는 maxIO)"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "EFS 처리량 모드 (bursting 또는 provisioned)"
  type        = string
  default     = "bursting"
}

variable "efs_transition_to_ia" {
  description = "IA(Infrequent Access) 스토리지 클래스로 전환할 기간"
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "team_vpc_id" {
  description = "The VPC ID from the network module"
  type        = string
}

variable "team_prisn_ids" {
  description = "The private subnet IDs from the network module"
  type        = list(string)
}