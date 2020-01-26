variable "route53_zone_name" {
  type        = map(string)
  description = "Route53 Zone Name (e.g. example.com.)"
}

variable "resource_name_prefix" {
  type        = map(string)
  description = "Resource Name Prefix required unique on AWS (e.g. review-spa)"
}

variable "api_domain" {
  type        = map(string)
  description = "API Domain (e.g. api-review-spa.example.com)"
}

variable "cdn_domain" {
  type        = map(string)
  description = "CDN Wildcard Domain (e.g. *.review-spa.example.com)"
}

variable "github_oauth_client_id" {
  type        = map(string)
  description = "GitHub OAuth Client ID"
}

variable "github_oauth_client_secret" {
  type        = map(string)
  description = "GitHub OAuth Client Secret"
}

variable "cdn_token_name" {
  type        = map(string)
  description = "CDN Auth Token Name (e.g. x-review-spa-token)"
}

variable "cdn_token_max_age" {
  type        = map(number)
  description = "CDN Auth Token Max Age second (e.g. 86400)"
}

variable "cdn_settings_json_filename" {
  type        = map(string)
  description = "CDN Settings JSON Filename on put origin (e.g. .review-spa.json)"
}
