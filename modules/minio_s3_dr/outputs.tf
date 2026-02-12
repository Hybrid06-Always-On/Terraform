output "bucket_names" {
  value = sort(keys(aws_s3_bucket.minio_dr))
}