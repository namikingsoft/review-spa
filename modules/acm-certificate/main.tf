resource "aws_acm_certificate" "ssl_dns" {
  provider = aws.global

  domain_name       = var.domain_name
  validation_method = "DNS"

  # Note
  tags = {
    Terraform = "true"
  }
}

resource "aws_route53_record" "for_acm" {
  zone_id = var.route53_zone_id
  name    = aws_acm_certificate.ssl_dns.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.ssl_dns.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.ssl_dns.domain_validation_options[0].resource_record_value]
  ttl     = "300"
}

resource "aws_acm_certificate_validation" "ssl_dns" {
  provider = aws.global

  certificate_arn         = aws_acm_certificate.ssl_dns.arn
  validation_record_fqdns = [aws_route53_record.for_acm.fqdn]
}
