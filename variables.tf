variable "route53_zone_name" {
  description = "Route53 Zone Name (e.g. example.com.)"
}

variable "resource_name_prefix" {
  description = "Resource Name Prefix required unique on AWS (e.g. review-spa)"
}

variable "review_spa_cdn_domain" {
  description = "CDN Wildcard Domain (e.g. *.review-spa.example.com)"
}

variable "review_spa_api_domain" {
  description = "API Domain (e.g. api-review-spa.example.com)"
}
