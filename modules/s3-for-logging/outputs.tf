output "id" {
  value = aws_s3_bucket.logging.id
}

output "domain_name" {
  value = aws_s3_bucket.logging.bucket_domain_name
}
