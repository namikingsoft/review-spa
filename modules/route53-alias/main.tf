resource "aws_route53_record" "alias" {
  zone_id = var.route53_zone_id
  name    = var.name
  type    = "A"

  alias {
    name                   = var.target
    zone_id                = var.route53_hosted_zone_id
    evaluate_target_health = false
  }
}
