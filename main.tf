data "aws_route53_zone" "review_spa_zone" {
  name = local.route53_zone_name
}

module "review_spa_cdn" {
  source = "./modules/review-spa-cdn"
  providers = {
    aws.global = aws.use1
  }

  comment              = "Review SPA CDN"
  default_ttl          = local.default_ttl
  wildcard_domain      = local.review_spa_cdn_domain
  route53_zone_id      = data.aws_route53_zone.review_spa_zone.zone_id
  resource_name_prefix = "${local.resource_name_prefix}-cdn"
}

module "review_spa_api" {
  source = "./modules/review-spa-api"
  providers = {
    aws.global = aws.use1
  }

  api_domain           = local.review_spa_api_domain
  cdn_domain           = local.review_spa_cdn_domain
  route53_zone_id      = data.aws_route53_zone.review_spa_zone.zone_id
  cf_distribution_id   = module.review_spa_cdn.cf_distribution_id
  origin_bucket_name   = module.review_spa_cdn.origin_bucket_name
  resource_name_prefix = "${local.resource_name_prefix}-api"
}
