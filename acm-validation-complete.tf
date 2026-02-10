resource "aws_acm_certificate_validation" "this" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation :
    record.fqdn
  ]
}

