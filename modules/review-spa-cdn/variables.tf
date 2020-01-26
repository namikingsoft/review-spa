variable "comment" {
  description = "AWS コンソールに表示されるメモ (e.g. 何でも良い)"
}

variable "wildcard_domain" {
  description = "ワイルドカードのドメイン名 (e.g. *.review-spa.example.io)"
}

variable "route53_zone_id" {
  description = "Route 53 の zone id (e.g. Z2LJA307ZAVHPI)"
}

variable "resource_name_prefix" {
  description = "Resource Name Prefix required unique on AWS (e.g. review-spa-cdn)"
}
