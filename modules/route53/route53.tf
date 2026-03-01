provider "aws" {
  region = "ap-northeast-2"
}

# 1. Hosted Zone
resource "aws_route53_zone" "this" {
  name = "alwaysonteam.store"
}

# 2. 온프레미스 헬스 체크
resource "aws_route53_health_check" "onprem" {
  ip_address        = "121.160.41.59"
  port              = 80
  type              = "TCP"
  # resource_path     = "/health"
  failure_threshold = 3
}

############################################################
# 🟢 WWW 도메인 (레코드 1, 2)
############################################################
resource "aws_route53_record" "www_primary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.alwaysonteam.store"
  type    = "A"
  ttl     = 60
  records = ["121.160.41.59"]
  set_identifier = "www-primary"
  health_check_id = aws_route53_health_check.onprem.id
  failover_routing_policy { type = "PRIMARY" }
}

resource "aws_route53_record" "www_secondary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.alwaysonteam.store"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
  set_identifier = "www-secondary"
  failover_routing_policy { type = "SECONDARY" }
}

############################################################
# 🔵 루트 도메인 (레코드 3, 4)
############################################################
resource "aws_route53_record" "root_primary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "alwaysonteam.store" # 루트 도메인
  type    = "A"
  ttl     = 60
  records = ["121.160.41.59"]
  set_identifier = "root-primary"
  health_check_id = aws_route53_health_check.onprem.id
  failover_routing_policy { type = "PRIMARY" }
}

resource "aws_route53_record" "root_secondary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "alwaysonteam.store" # 루트 도메인
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
  set_identifier = "root-secondary"
  failover_routing_policy { type = "SECONDARY" }
}