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

# 4. MinIO S3  모듈 호출
module "minio_s3_dr" {
  source = "./modules/minio_s3_dr"

}

# 5. Monitoring 모듈 호출
module "monitoring" {
  source     = "./modules/monitoring"
  depends_on = [module.eks_cluster]
}

module "datasync_agent" {
  source = "./modules/datasync_agent"

  team_vpc_id    = module.network.team_vpc_id
  team_pubsn_ids = module.network.team_pubsn_ids
  team_prisn_ids = module.network.team_prisn_ids
}
# 6. Cluster DR 모듈 호출
# 온프레미스 장애 시 Route53 HealthCheck → SNS → CloudWatch Alarm → Lambda → EKS scale-up을 수행
module "cluster_dr" {
  source = "./modules/cluster_dr"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  # EKS 클러스터 정보
  team_vpc_id           = module.network.team_vpc_id
  team_cluster_name     = module.network.team_cluster_name
  team_cluster_endpoint = module.eks_cluster.cluster_endpoint
  team_prisn_ids        = module.network.team_prisn_ids
}
