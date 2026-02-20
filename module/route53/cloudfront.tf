############################################
# 🔐 CloudFront Signed URL용 키 설정
############################################
resource "aws_cloudfront_public_key" "signed" {
  provider    = aws.use1
  name        = "alwayson-signed-key"
  encoded_key = file("/home/tf/.ssh/cloudfront_public.pem")
}

resource "aws_cloudfront_key_group" "signed" {
  provider = aws.use1
  name     = "alwayson-signed-group"
  items    = [aws_cloudfront_public_key.signed.id]
  depends_on = [aws_cloudfront_public_key.signed]
}

############################################
# 🌍 CloudFront Distribution
############################################
resource "aws_cloudfront_distribution" "this" {
  provider   = aws.use1
  depends_on = [aws_acm_certificate_validation.this]
  enabled    = true

  # API 서버 형태이므로 기본 루트 오브젝트는 비워둠
  default_root_object = "" 

  aliases = [
    "alwaysonteam.store",
    "www.alwaysonteam.store"
  ]

  ################################################
  # 🔵 Origin 설정
  ################################################
  origin {
    domain_name = "k8s-default-testingr-0c218d6212-566298767.ap-northeast-2.elb.amazonaws.com"
    
    # [수정 위치 1] 이름표(ID)를 ALB DNS 주소로 설정
    origin_id   = "k8s-default-testingr-0c218d6212-566298767.ap-northeast-2.elb.amazonaws.com" 

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ################################################
  # ⭐ Default Cache Behavior (일반 접속)
  ################################################
  default_cache_behavior {
    # [수정 위치 2] 위 origin_id와 일치시킴
    target_origin_id       = "k8s-default-testingr-0c218d6212-566298767.ap-northeast-2.elb.amazonaws.com" 
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Authorization", "Accept"]
      cookies {
        forward = "all"
      }
    }
  }

  ################################################
  # 🔐 보안 경로 1: /api/* (Signed URL 필수)
  ################################################
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    # [수정 위치 3] 위 origin_id와 일치시킴
    target_origin_id = "k8s-default-testingr-0c218d6212-566298767.ap-northeast-2.elb.amazonaws.com" 
    
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    trusted_key_groups = [aws_cloudfront_key_group.signed.id]

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Authorization", "Accept"]
      cookies { forward = "all" }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  ################################################
  # 🔐 보안 경로 2: /video-hls/* (Signed URL 필수)
  ################################################
  ordered_cache_behavior {
    path_pattern     = "/video-hls/*"
    # [수정 위치 4] 위 origin_id와 일치시킴
    target_origin_id = "k8s-default-testingr-0c218d6212-566298767.ap-northeast-2.elb.amazonaws.com" 
    
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    trusted_key_groups = [aws_cloudfront_key_group.signed.id]

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ################################################
  # 🔐 보안 경로 3: /video-thumb/* (Signed URL 필수)
  ################################################
  ordered_cache_behavior {
    path_pattern     = "/video-thumb/*"
    # [수정 위치 5] 위 origin_id와 일치시킴
    target_origin_id = "k8s-default-testingr-0c218d6212-566298767.ap-northeast-2.elb.amazonaws.com" 
    
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    trusted_key_groups = [aws_cloudfront_key_group.signed.id]

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "AlwaysOn-CloudFront-Final"
  }
}