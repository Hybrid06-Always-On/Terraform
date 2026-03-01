variable "team_vpc_id" {
  description = "The VPC ID from the network module"
  type        = string
}

variable "team_prisn_ids" {
  description = "The private subnet IDs from the network module"
  type        = list(string)
}

variable "team_pubsn_ids" {
  description = "The public subnet IDs from the network module"
  type        = list(string)
}

variable "name" {
  type    = string
  default = "team-datasync-agent"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "subnet_index" {
  type    = number
  default = 0
}
