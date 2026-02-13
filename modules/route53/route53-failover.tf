############################################
# 1️⃣ 온프레미스 Health Check
############################################
resource "aws_route53_health_check" "onprem" {
  ip_address        = "너의_공인_IP"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

############################################
# 2️⃣ PRIMARY (온프레미스)
############################################
resource "aws_route53_record" "primary_root" {
  zone_id = aws_route53_zone.this.zone_id
  name    = ""
  type    = "A"

  set_identifier = "primary-onprem"
  failover       = "PRIMARY"

  ttl     = 60
  records = ["너의_공인_IP"]

  health_check_id = aws_route53_health_check.onprem.id
}

resource "aws_route53_record" "primary_www" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www"
  type    = "A"

  set_identifier = "primary-onprem-www"
  failover       = "PRIMARY"

  ttl     = 60
  records = ["너의_공인_IP"]

  health_check_id = aws_route53_health_check.onprem.id
}

############################################
# 3️⃣ SECONDARY (CloudFront)
############################################
resource "aws_route53_record" "secondary_root" {
  zone_id = aws_route53_zone.this.zone_id
  name    = ""
  type    = "A"

  set_identifier = "secondary-cloud"
  failover       = "SECONDARY"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "secondary_www" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www"
  type    = "A"

  set_identifier = "secondary-cloud-www"
  failover       = "SECONDARY"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
