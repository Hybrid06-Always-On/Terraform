# S3 Bucket 생성
resource "aws_s3_bucket" "team_tfstate" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true # S3 Bucket 삭제 방지
  }

  tags = {
    Name = var.bucket_name
  }
}

# S3 Bucket 버전 기능 활성화
resource "aws_s3_bucket_versioning" "team_tfstate_versioning" {
  bucket = aws_s3_bucket.team_tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket 서버측 암호화 방식 선택(SSE|KMS)
resource "aws_s3_bucket_server_side_encryption_configuration" "team_tfstate_encryption" {
  bucket = aws_s3_bucket.team_tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access 차단
resource "aws_s3_bucket_public_access_block" "team_tfstate_public_access" {
  bucket                  = aws_s3_bucket.team_tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

