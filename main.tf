# common

data "aws_route53_zone" "review_for_spa_zone" {
  name = local.route53_zone_name
}

# review_for_spa

module "review_for_spa_acm" {
  source = "./modules/acm-certificate"
  providers = {
    aws.global = aws.use1
  }

  domain_name     = local.review_for_spa_app_domain
  route53_zone_id = data.aws_route53_zone.review_for_spa_zone.zone_id
}

module "review_for_spa_dns" {
  source = "./modules/route53-alias"

  name                   = local.review_for_spa_app_domain
  target                 = module.review_for_spa_cdn.domain_name
  route53_zone_id        = data.aws_route53_zone.review_for_spa_zone.zone_id
  route53_hosted_zone_id = module.review_for_spa_cdn.hosted_zone_id
  tag_name               = "terraform"
}

module "review_for_spa_cdn" {
  source = "./modules/cloudfront-via-s3"

  comment             = "Review for SPA CDN"
  origin_bucket_name  = local.review_for_spa_app_name
  default_ttl         = local.review_for_spa_default_ttl
  logging_bucket_name = module.review_for_spa_logging.domain_name
  aliases             = [local.review_for_spa_app_domain]
  acm_certificate_arn = module.review_for_spa_acm.acm_certification_arn
}


module "review_for_spa_logging" {
  source = "./modules/s3-for-logging"

  bucket_name = local.review_for_spa_logging_bucket_name
}

# logging

module "logging-to-partition" {
  source = "./modules/lambda-to-partition"

  function_name = local.to_partition_function_name
  bucket_ids    = [module.review_for_spa_logging.id]
}
