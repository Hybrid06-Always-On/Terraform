variable "team_vpc_cidr" {
  type    = string
  default = "20.0.0.0/16"
}

variable "team_azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

variable "team_public_subnets" {
  type    = list(string)
  default = ["20.0.1.0/24", "20.0.2.0/24", "20.0.3.0/24"]
}

variable "team_private_subnets" {
  type    = list(string)
  default = ["20.0.4.0/24", "20.0.5.0/24", "20.0.6.0/24"]
}

variable "cluster_name" {
  type    = string
  default = "team-cluster"
}
