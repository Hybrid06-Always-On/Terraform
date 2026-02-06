variable "team_vpc_cidr" {
  type    = string
  default = "10.5.0.0/16"
}

variable "team_azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

variable "team_public_subnets" {
  type    = list(string)
  default = ["10.5.5.0/24", "10.5.6.0/24", "10.5.7.0/24"]
}

variable "team_private_subnets" {
  type    = list(string)
  default = ["10.5.8.0/24", "10.5.9.0/24", "10.5.10.0/24"]
}

variable "cluster_name" {
  type    = string
  default = "team-cluster"
}
