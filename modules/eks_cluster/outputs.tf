# EKS 클러스터 정보 출력
output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS 클러스터 엔드포인트"
  value       = module.eks.cluster_endpoint
}

# kubeconfig 업데이트 명령어
output "update_kubeconfig_command" {
  description = "kubeconfig 업데이트를 위한 AWS CLI 명령어"
  value       = "aws eks update-kubeconfig --region ap-northeast-2 --name ${module.eks.cluster_name} --profile process"
}
