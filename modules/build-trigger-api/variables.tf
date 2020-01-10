variable "function_name" {
  description = "Lambda の関数名 (e.g. build-trigger-api)"
}
variable "domain" {
  description = "API ドメイン (e.g. api.example.com)"
}

variable "route53_zone_id" {
  description = "Route 53 の zone id (e.g. Z2LJA307ZAVHPI)"
}