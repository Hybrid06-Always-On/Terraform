#############################################
# S3 DR 버킷 생성
# → MinIO DR 데이터를 저장할 기본 버킷 생성
#############################################
resource "aws_s3_bucket" "minio_dr" {
  for_each = toset(var.dr_buckets)

  bucket = each.value
  tags = var.tags
}

#############################################
# S3 버전 관리 활성화
# → 객체 변경/삭제 시 복구 가능
#############################################
resource "aws_s3_bucket_versioning" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

#############################################
# 서버 측 암호화 설정
# → S3 저장 데이터 자동 암호화
#############################################
resource "aws_s3_bucket_server_side_encryption_configuration" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#############################################
# 퍼블릭 접근 차단
# → 외부 공개 방지 (보안)
#############################################
resource "aws_s3_bucket_public_access_block" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#############################################
# 버킷 소유권 강제 설정
# → 객체 권한 충돌 방지
#############################################
resource "aws_s3_bucket_ownership_controls" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

#############################################
# S3 라이프사이클 정책
# → 오래된 데이터 비용 절감용 스토리지 전환
#############################################
resource "aws_s3_bucket_lifecycle_configuration" "minio_dr" {

  for_each = {
    for k, v in aws_s3_bucket.minio_dr :
    k => v if k != "alwayson-video-thumb"
  }

  bucket = each.value.id

  rule {
    id     = "dr-transition"
    status = "Enabled"

    filter {} 

    # 최근 데이터는 STANDARD 유지
    transition {
      days          = var.lifecycle_days
      storage_class = "STANDARD_IA"
    }

    # 이전 버전도 동일 정책
    noncurrent_version_transition {
      noncurrent_days = var.lifecycle_days
      storage_class   = "STANDARD_IA"
    }
  }
}

#############################################
# S3 Bucket Policy (CloudFront 전용 접근 허용)
#############################################
resource "aws_s3_bucket_policy" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${each.value.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::260028436792:distribution/E144GFIYUBXADB"
          }
        }
      }
    ]
  })
}

#############################################
# S3 CORS 설정
# → CloudFront / Web Frontend 접근 허용
#############################################
resource "aws_s3_bucket_cors_configuration" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [
      "https://alwaysonteam.store",
      "https://www.alwaysonteam.store"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}