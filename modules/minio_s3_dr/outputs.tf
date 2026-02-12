output "minio_dr_buckets" {
  description = "MinIO → AWS S3 DR로 생성된 버킷 목록"

  value = [
    for b in aws_s3_bucket.minio_dr :
    b.bucket
  ]
}
