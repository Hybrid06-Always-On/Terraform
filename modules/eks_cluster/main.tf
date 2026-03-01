# locals {
#   team_vpc_id       = data.terraform_remote_state.network_module.outputs.team_vpc_id
#   team_cluster_name = data.terraform_remote_state.network_module.outputs.team_cluster_name
#   team_prisn_ids    = data.terraform_remote_state.network_module.outputs.team_prisn_ids
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = var.team_cluster_name
  kubernetes_version = "1.34"

  # 애드온 설치
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  # endpoint 설정
  endpoint_public_access  = true
  endpoint_private_access = false

  # IAM 자동 생성
  create_auto_mode_iam_resources = true

  vpc_id                   = var.team_vpc_id
  subnet_ids               = var.team_prisn_ids # Worker Node Subnet
  control_plane_subnet_ids = var.team_prisn_ids # Control Plane Subnet

  # EKS Worker Node Group
  eks_managed_node_groups = {
    team_node_group = {
      ami_type      = "AL2023_x86_64_STANDARD"
      instance_type = ["m6i.large"] # 테스트: t3.medium / 운영: m6i.large

      min_size     = 2 # 최소 워커노드 수
      max_size     = 3 # 최대 워커노드 수
      desired_size = 2 # 초기 워커노드 수
    }
  }

  # Tag 지정
  tags = {
    Project     = "team"
    Environment = "prod"
  }
}

# 현재 AWS 계정 ID 가져오기
data "aws_caller_identity" "current" {}

# IAM 사용자들에게 EKS 클러스터 접근 권한 부여
resource "aws_eks_access_entry" "eks_admin_users" {
  for_each = var.team_eks_admin_users

  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${each.value}"
  type          = "STANDARD"

  depends_on = [module.eks]
}

# EKS 클러스터 관리자 정책 연결
resource "aws_eks_access_policy_association" "eks_admin_policy" {
  for_each = var.team_eks_admin_users

  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${each.value}"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.eks_admin_users]
}
