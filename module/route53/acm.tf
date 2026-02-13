provider "aws" {
  alias  = "use1"
  region = "us-east-1" # CloudFront용 SSL 인증서
}

resource "aws_acm_certificate" "this" {
  provider          = aws.use1
  domain_name       = "alwaysonteam.store"
  validation_method = "DNS"
  subject_alternative_names = ["www.alwaysonteam.store"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "this" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
