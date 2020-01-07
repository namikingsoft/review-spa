output "acm_certification_arn" {
  value = aws_acm_certificate_validation.ssl_dns.certificate_arn
}
