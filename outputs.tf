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

output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS 클러스터 엔드포인트"
  value       = module.eks_cluster.cluster_endpoint
}

output "update_kubeconfig_command" {
  description = "kubeconfig 업데이트를 위한 AWS CLI 명령어"
  value       = "aws eks update-kubeconfig --region ap-northeast-2 --name ${module.eks_cluster.cluster_name} --profile process"
}
