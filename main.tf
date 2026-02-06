# 1. Network 모듈 호출
# VPC, Subnet, Security Group 등을 생성합니다.
module "network" {
  source = "./modules/network"
}

# 2. Aurora DB 모듈 호출
module "aurora_db" {
  source = "./modules/auroradb"

  vpc_id      = module.network.team_vpc_id
  db_username = var.db_username
  db_password = var.db_password
}
