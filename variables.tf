variable "route53_zone_name" {
  description = "Route53 Zone Name (e.g. example.com.)"
}

variable "review_spa_app_name" {
  description = "App Name (e.g. review-spa)"
}

variable "review_spa_cdn_domain" {
  description = "CDN Wildcard Domain (e.g. *.review-spa.example.com)"
}

variable "review_spa_api_domain" {
  description = "API Domain (e.g. api-review-spa.example.com)"
}
