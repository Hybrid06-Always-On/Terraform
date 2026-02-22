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
}

############################################
# 🌍 CloudFront Distribution
############################################
resource "aws_cloudfront_distribution" "this" {
  provider   = aws.use1
  depends_on = [aws_acm_certificate_validation.this]
  enabled    = true

  aliases = [
    "alwaysonteam.store",
    "www.alwaysonteam.store"
  ]

  ################################################
  # 🔵 Origin 설정 (ALB 80번 포트 전용 설정)
  ################################################
  
  # 1. API & Default용 ALB
  origin {
    domain_name = "k8s-app-backendi-20f5a272f2-919536847.ap-northeast-2.elb.amazonaws.com"
    origin_id   = "alb-backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      # 조원분 피드백 반영: ALB는 80번 포트(HTTP)로만 접근
      origin_protocol_policy = "http-only" 
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # 2. HLS 영상용 S3 버킷
  origin {
    domain_name = "alwayson-video-hls.s3.ap-northeast-2.amazonaws.com" 
    origin_id   = "s3-hls"
  }

  # 3. 썸네일용 S3 버킷
  origin {
    domain_name = "alwayson-video-thumb.s3.ap-northeast-2.amazonaws.com"
    origin_id   = "s3-thumb"
  }

  ################################################
  # ⭐ Cache Behavior
  ################################################

  # [순서 1] /api/* -> ALB (조원분 요청 반영)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "alb-backend"
    
    # 조원분 피드백: 리디렉션 제거
    viewer_protocol_policy = "allow-all" 

    allowed_methods  = ["GET","HEAD","OPTIONS","PUT","POST","PATCH","DELETE"]
    cached_methods   = ["GET","HEAD"]

    # ⚠️ 만약 API 호출 시 서명(Signed URL)을 쓰지 않는다면 아래 라인을 지우세요!
    trusted_key_groups = [aws_cloudfront_key_group.signed.id]

    forwarded_values {
      query_string = true
      headers      = ["Host","Origin","Authorization","Accept"]
      cookies { forward = "all" }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # [순서 2] *.m3u8, *.ts, *.jpg (S3용 - 이전과 동일하게 CORS 설정 유지)
  ordered_cache_behavior {
    path_pattern     = "*.m3u8"
    target_origin_id = "s3-hls"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET","HEAD","OPTIONS"]
    cached_methods  = ["GET","HEAD"]
    trusted_key_groups = [aws_cloudfront_key_group.signed.id]
    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      cookies { forward = "none" }
    }
  }

  # [Default] * -> ALB (리디렉션 제거)
  default_cache_behavior {
    target_origin_id       = "alb-backend"
    viewer_protocol_policy = "allow-all" 

    allowed_methods  = ["GET","HEAD","OPTIONS","PUT","POST","PATCH","DELETE"]
    cached_methods   = ["GET","HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Host","Origin","Authorization","Accept"]
      cookies { forward = "all" }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
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
}
