################################
# Required infra
################################

variable "team_vpc_id" {
  type = string
}

variable "team_prisn_rtb_id" {
  type = list(string)
}

################################
# DR config
################################

variable "dr_buckets" {
  type = list(string)

  default = [
    "alwayson-video-hls",
    "alwayson-video-thumb"
  ]
}

variable "tags" {
  type = map(string)

  default = {
    Project = "AlwaysOn-DR"
  }
}

variable "lifecycle_days" {
  type    = number
  default = 30
}