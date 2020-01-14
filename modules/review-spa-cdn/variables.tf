variable "comment" {
  description = "AWS コンソールに表示されるメモ (e.g. 何でも良い)"
}

variable "origin_bucket_name" {
  description = "オリジン S3 バケット名 (e.g. review-spa-production)"
}

variable "default_ttl" {
  description = "Default TTL (e.g. 604800)"
}

variable "logging_bucket_name" {
  description = "ログアーカイブ先の S3 バケット (e.g. review-spa-logging)"
}

variable "wildcard_domain" {
  description = "ワイルドカードのドメイン名 (e.g. *.review-spa.example.io)"
}

variable "function_name" {
  description = "Lambda Edge の関数名 (e.g. urlrewrite-for-spa)"
}

variable "route53_zone_id" {
  description = "Route 53 の zone id (e.g. Z2LJA307ZAVHPI)"
}
