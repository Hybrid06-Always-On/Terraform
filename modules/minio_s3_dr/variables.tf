#################################
# Required infra
#################################

variable "team_vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "team_prisn_rtb_id" {
  description = "Private route table IDs"
  type        = list(string)
}

#################################
# DR config
#################################

variable "dr_buckets" {
  description = "MinIO DR 대상 S3 버킷 목록"
  type        = list(string)

  default = [
    "alwayson-video-hls",
    "alwayson-video-thumb"
  ]
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)

  default = {
    Project = "AlwaysOn-DR"
  }
}

variable "lifecycle_days" {
  description = "Lifecycle 전환 기준 일"
  type        = number
  default     = 30
}
