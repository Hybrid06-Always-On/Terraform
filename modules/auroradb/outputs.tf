output "cluster_endpoint" {
  description = "Aurora Cluster Writer 엔드포인트 (쓰기용 / 복제 대상 주소)"
  value       = aws_rds_cluster.aurora.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora Cluster Reader 엔드포인트 (읽기 전용)"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "db_sg_id" {
  description = "Aurora 보안 그룹 ID"
  value       = aws_security_group.aurora_sg.id
}

output "cluster_identifier" {
  description = "Aurora Cluster ID (CloudWatch 모니터링용)"
  value       = aws_rds_cluster.aurora.cluster_identifier
}
