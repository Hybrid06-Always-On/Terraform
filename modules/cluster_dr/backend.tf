# route53 module 출력 변수 참조
data "terraform_remote_state" "route_53" {
  backend = "s3"
  config = {
    bucket  = "team-tfstate-bucket"
    key     = "modules/route53/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "process"
  }
}

