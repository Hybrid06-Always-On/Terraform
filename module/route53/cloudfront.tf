resource "aws_cloudfront_distribution" "this" {
  provider   = aws.use1
  depends_on = [aws_acm_certificate_validation.this] # 인증서 검증 후 배포
  enabled    = true
  default_root_object = "index.html"

  aliases = [
    "alwaysonteam.store",
    "www.alwaysonteam.store"
  ]

  origin {
    domain_name = "onprem.alwaysonteam.store"
    origin_id   = "onprem-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "onprem-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
}
