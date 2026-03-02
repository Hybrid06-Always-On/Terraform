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
  # 🔵 Origin 설정
  ################################################
  
  # 1. API & Default용 ALB (80번 포트 고정)
  origin {
    domain_name = "k8s-app-backendi-20f5a272f2-919536847.ap-northeast-2.elb.amazonaws.com"
    origin_id   = "alb-backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # 조원분 요청 사항 반영
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # 2. HLS 영상용 S3 버킷
  origin {
    domain_name = "alwayson-video-hls.s3.ap-northeast-2.amazonaws.com" 
    origin_id   = "s3-hls"
    # 만약 OAC(Origin Access Control)를 테라폼으로 관리한다면 여기에 설정이 추가되지만,
    # 현재 수동으로 정책을 넣으셨으므로 origin_id 매칭만 정확히 하면 됩니다.
  }

  # 3. 썸네일용 S3 버킷
  origin {
    domain_name = "alwayson-video-thumb.s3.ap-northeast-2.amazonaws.com"
    origin_id   = "s3-thumb"
  }

  ################################################
  # ⭐ Cache Behavior
  ################################################

  # [순서 1] /api/* -> ALB (리디렉션 X, 서명 X)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "alb-backend"
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

  # [순서 2] *.m3u8 -> S3 HLS (CORS & 서명 해결 핵심)
  ordered_cache_behavior {
    path_pattern     = "*.m3u8"
    target_origin_id = "s3-hls"
    viewer_protocol_policy = "redirect-to-https"

    # OPTIONS 메서드가 허용되어야 브라우저의 CORS 사전 검사가 통과됩니다.
    allowed_methods = ["GET","HEAD","OPTIONS"]
    cached_methods  = ["GET","HEAD"]

    trusted_key_groups = [aws_cloudfront_key_group.signed.id]

    forwarded_values {
      query_string = true # Signed URL 쿼리 파라미터를 S3로 전달 (403 방지)
      
      # [핵심] S3의 CORS 설정을 깨우기 위해 브라우저 정보를 배달합니다.
      headers = [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method"
      ]

      cookies { forward = "none" }
    }
  }

  # [순서 3] *.ts -> S3 HLS (영상 조각 파일)
  ordered_cache_behavior {
    path_pattern     = "*.ts"
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

  # [순서 4] *.jpg -> S3 Thumb (썸네일 이미지)
  ordered_cache_behavior {
    path_pattern     = "*.jpg"
    target_origin_id = "s3-thumb"
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

  # [Default] * -> ALB (나머지 모든 경로)
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
