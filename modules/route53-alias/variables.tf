variable "name" {
  description = "Route 53 レコードの name (e.g. app.dfplus.io)"
}

variable "target" {
  description = "alias の hostname (e.g. d2xxxksefs.cloudfront.net)"
}

variable "route53_zone_id" {
  description = "Route 53 の zone id (e.g. Z2R2W5H9ALCKC5)"
}

variable "route53_hosted_zone_id" {
  description = "Route 53 の Hosted zone id (e.g. Z2R2W5H9ALCKC5)"
}

variable "tag_name" {
  description = "tag の Name 値 (e.g. via-terraform)"
}
