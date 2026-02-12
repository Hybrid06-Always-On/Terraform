resource "aws_s3_bucket" "minio_dr" {
  for_each = toset(var.dr_buckets)

  bucket = each.value
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "minio_dr" {
  for_each = aws_s3_bucket.minio_dr

  bucket = each.value.id

  rule {
    id     = "dr-transition"
    status = "Enabled"

    transition {
      days          = var.lifecycle_days
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}