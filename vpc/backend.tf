terraform {
  backend "s3" {
    bucket       = "team-tfstate-bucket"
    key          = "module/vpc/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
    profile      = "process"
  }
}

