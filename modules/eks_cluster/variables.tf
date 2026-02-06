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
