variable "team_vpc_id" {
  description = "The VPC ID from the network module"
  type        = string
}

variable "team_cluster_name" {
  description = "The cluster name from the network module"
  type        = string
}

variable "team_prisn_ids" {
  description = "The private subnet IDs from the network module"
  type        = list(string)
}

# EKS 클러스터 관리자 사용자 목록
variable "team_eks_admin_users" {
  description = "EKS 클러스터에 대한 관리자 권한을 가진 IAM 사용자 이름 목록"
  type        = set(string)
  default     = ["arjleun", "ishwa"]
}
