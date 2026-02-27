# terraform {
#   backend "s3" {
#     bucket       = "team-tfstate-bucket"
#     key          = "module/eks_cluster/terraform.tfstate"
#     region       = "ap-northeast-2"
#     use_lockfile = true # lock 파일 저장
#     encrypt      = true # 암호화 저장
#     profile      = "process"
#   }
# }

# # network module 출력 변수 참조
# data "terraform_remote_state" "network_module" {
#   backend = "s3"
#   config = {
#     bucket  = "team-tfstate-bucket"
#     key     = "module/network/terraform.tfstate"
#     region  = "ap-northeast-2"
#     profile = "process"
#   }
# }
