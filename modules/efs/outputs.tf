output "efs_id" {
  description = "생성된 EFS 파일 시스템의 ID"
  value       = aws_efs_file_system.this.id
}

output "efs_access_point_id" {
  description = "생성된 EFS 액세스 포인트의 ID (헬름 SC에 사용)"
  value       = aws_efs_access_point.video_data.id
}

output "efs_security_group_id" {
  description = "EFS 전용 보안 그룹 ID"
  value       = aws_security_group.efs_sg.id
}

output "efs_arn" {
  description = "EFS의 ARN (DataSync 설정 시 필요할 수 있음)"
  value       = aws_efs_file_system.this.arn
}