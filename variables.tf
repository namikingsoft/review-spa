variable "route53_zone_name" {
  type        = map(string)
  description = "Route53 Zone Name (e.g. example.com.)"
}

variable "resource_name_prefix" {
  type        = map(string)
  description = "Resource Name Prefix required unique on AWS (e.g. review-spa)"
}

variable "review_spa_cdn_domain" {
  type        = map(string)
  description = "CDN Wildcard Domain (e.g. *.review-spa.example.com)"
}

variable "review_spa_api_domain" {
  type        = map(string)
  description = "API Domain (e.g. api-review-spa.example.com)"
}
