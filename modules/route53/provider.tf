provider "aws" {
  region = "ap-northeast-2"  # 서울 (Route53, ALB 등)
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"       # CloudFront용 ACM
}
