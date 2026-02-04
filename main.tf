# 최상위 main.tf

module "aurora_db" {
  source = "./modules/auroradb"

  # terraform.tfvars에서 읽어온 변수들을 모듈로 전달
  vpc_id      = var.vpc_id
  db_username = var.db_username
  db_password = var.db_password
}
