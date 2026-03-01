terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # 서울 리전
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1" # 버지니아 리전 프로바이더 (Route 53 알람 전용)
}

