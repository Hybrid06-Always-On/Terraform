resource "aws_acm_certificate" "this" {
  provider          = aws.use1
  domain_name       = "alwaysonteam.store"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.alwaysonteam.store"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

