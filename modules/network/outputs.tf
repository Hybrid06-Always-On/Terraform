output "team_vpc_id" {
  value = aws_vpc.team_VPC.id
}

output "team_pubsn_ids" {
  value = aws_subnet.team_PubSN[*].id
}

output "team_prisn_ids" {
  value = aws_subnet.team_PriSN[*].id
}

output "team_cluster_name" {
  value = var.cluster_name
}
