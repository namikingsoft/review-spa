variable "comment" {
  description = "AWS コンソールに表示されるメモ (e.g. 何でも良い)"
}

variable "wildcard_domain" {
  description = "ワイルドカードのドメイン名 (e.g. *.review-spa.example.io)"
}

variable "cdn_token_name" {
  description = "CDN Auth Token Name (e.g. x-review-spa-token)"
  default     = "x-review-spa-token"
}

variable "cdn_token_max_age" {
  description = "CDN Auth Token Max Age second (e.g. 86400)"
  default     = 86400
}

variable "github_oauth_client_id" {
  description = "GitHub OAuth Client ID"
  default     = null
}

variable "github_oauth_client_secret" {
  description = "GitHub OAuth Client Secret"
  default     = null
}

variable "route53_zone_id" {
  description = "Route 53 の zone id (e.g. Z2LJA307ZAVHPI)"
}

variable "resource_name_prefix" {
  description = "Resource Name Prefix required unique on AWS (e.g. review-spa-cdn)"
}
