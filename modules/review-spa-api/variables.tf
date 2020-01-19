variable "cf_distribution_id" {
  description = "Cloudfront Distirbution ID (e.g. E2NGxxxxxxLIIR)"
}

variable "origin_bucket_name" {
  description = "オリジン S3 バケット名 (e.g. anything-bucket-name)"
}

variable "api_domain" {
  description = "API ドメイン (e.g. api.example.com)"
}

variable "cdn_domain" {
  description = "CDN ドメイン (e.g. *.api.example.com)"
}

variable "route53_zone_id" {
  description = "Route 53 の zone id (e.g. Z2LJA307ZAVHPI)"
}

variable "resource_name_prefix" {
  description = "Resource Name Prefix required unique on AWS (e.g. review-spa-api)"
}
