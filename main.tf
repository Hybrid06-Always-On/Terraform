# network 모듈 호출
module "network" {
  source = "./modules/network"
}

# eks 모듈 호출
module "eks_cluster" {
  source = "./modules/eks_cluster"

  team_vpc_id       = module.network.team_vpc_id
  team_cluster_name = module.network.team_cluster_name
  team_prisn_ids    = module.network.team_prisn_ids
}
