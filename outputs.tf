output "team_vpc_id" {
  value = module.network.team_vpc_id
}

output "team_pubsn_ids" {
  value = module.network.team_pubsn_ids
}

output "team_prisn_ids" {
  value = module.network.team_prisn_ids
}

output "team_cluster_name" {
  value = module.network.team_cluster_name
}

output "aurora_cluster_endpoint" {
  description = "Aurora Cluster Writer 엔드포인트"
  value       = module.aurora_db.cluster_endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora Cluster Reader 엔드포인트"
  value       = module.aurora_db.cluster_reader_endpoint
}

output "aurora_db_sg_id" {
  description = "Aurora 보안 그룹 ID"
  value       = module.aurora_db.db_sg_id
}
