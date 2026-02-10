# 1. Network 모듈 호출
module "network" {
  source = "./modules/network"
}

# 2. Aurora DB 모듈 호출
module "aurora_db" {
  source = "./modules/auroradb"

  # 네트워크 모듈과 연계
  team_vpc_id    = module.network.team_vpc_id
  team_prisn_ids = module.network.team_prisn_ids

  # 설정값
  instance_count = var.instance_count
  db_username    = var.db_username
  db_password    = var.db_password
}

# 3. EKS Cluster 모듈 호출
module "eks_cluster" {
  source = "./modules/eks_cluster"

  team_vpc_id       = module.network.team_vpc_id
  team_cluster_name = module.network.team_cluster_name
  team_prisn_ids    = module.network.team_prisn_ids
}
