output "cf_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "origin_bucket_name" {
  value = aws_s3_bucket.origin.bucket
}
