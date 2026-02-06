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
      instance_type = ["m5.large"]

      min_size     = 3
      max_size     = 5
      desired_size = 3
    }
  }

  # Tag 지정
  tags = {
    Project     = "team"
    Environment = "prod"
  }
}
