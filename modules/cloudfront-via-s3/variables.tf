variable "comment" {
  description = "AWS コンソールに表示されるメモ (e.g. 何でも良い)"
}

variable "origin_bucket_name" {
  description = "オリジン S3 バケット名 (e.g. review-for-spa-production)"
}

variable "default_ttl" {
  description = "Default TTL (e.g. 604800)"
}

variable "logging_bucket_name" {
  description = "ログアーカイブ先の S3 バケット (e.g. review-for-spa-logging)"
}

variable "acm_certificate_arn" {
  description = "ACM 証明書の ARN (e.g. arn:****)"
}

variable "aliases" {
  type        = list(string)
  default     = []
  description = "別名のドメイン名 (e.g. review-for-spa.example.io)"
}

variable "lambda_arns" {
  type        = list(string)
  default     = []
  description = "Origin-Request に設定する Lambda Edge の ARN 配列 (e.g. [arn:****])"
}