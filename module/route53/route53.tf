provider "aws" {
  region = "ap-northeast-2" # Route53 + 온프레미스 HealthCheck
}

resource "aws_route53_zone" "this" {
  name = "alwaysonteam.store"
}

# 온프레미스 Health Check
resource "aws_route53_health_check" "onprem" {
  fqdn              = "onprem.alwaysonteam.store"
  type              = "HTTPS"
  port              = 443
  resource_path     = "/"
  failure_threshold = 3
}

# 온프레미스 Primary A 레코드
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.alwaysonteam.store"
  type    = "A"
  ttl     = 60
  records = ["121.160.41.59"]

  set_identifier    = "Primary-onprem"
  health_check_id   = aws_route53_health_check.onprem.id
  failover_routing_policy {
    type = "PRIMARY"
  }
}

# CloudFront Secondary 레코드
resource "aws_route53_record" "secondary" {
  provider = aws.use1
  zone_id  = aws_route53_zone.this.zone_id
  name     = "www.alwaysonteam.store"
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }

  set_identifier = "Secondary-cloudfront"
  failover_routing_policy {
    type = "SECONDARY"
  }
}

