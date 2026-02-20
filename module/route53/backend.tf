terraform {
  backend "s3" {
    bucket       = "team-tfstate-bucket"
    key          = "modules/route53/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true # lock 파일 저장
    encrypt      = true # 암호화 저장
    profile      = "process"
  }
}
