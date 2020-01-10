variable "function_name" {
  description = "Lambda の関数名 (e.g. build-trigger-api)"
}

variable "temp_archive_bucket_name" {
  description = "CI に dist を渡すために、一時的にアーカイブファイルを置く S3 バケット名 (e.g. temp-archive-files)"
}

variable "domain" {
  description = "API ドメイン (e.g. api.example.com)"
}

variable "route53_zone_id" {
  description = "Route 53 の zone id (e.g. Z2LJA307ZAVHPI)"
}

variable "circle_token" {
  description = "CircleCI Personal Token を指定"
}