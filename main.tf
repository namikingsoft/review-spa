data "aws_route53_zone" "review_spa_zone" {
  name = var.route53_zone_name
}

module "review_spa_logging" {
  source = "./modules/s3-for-logging"

  bucket_name = "${var.review_spa_app_name}-logging"
}

module "review_spa_logging_to_partition" {
  source = "./modules/lambda-to-partition"

  function_name = "${var.review_spa_app_name}-logging-to-partition"
  bucket_ids    = [module.review_spa_logging.id]
}

module "review_spa_cdn" {
  source = "./modules/review-spa-cdn"
  providers = {
    aws.global = aws.use1
  }

  comment             = "Review SPA CDN"
  origin_bucket_name  = "${var.review_spa_app_name}-origin"
  default_ttl         = local.default_ttl
  logging_bucket_name = module.review_spa_logging.domain_name
  wildcard_domain     = var.review_spa_cdn_domain
  function_name       = "${var.review_spa_app_name}-urlrewrite"
  route53_zone_id     = data.aws_route53_zone.review_spa_zone.zone_id
}

module "review_spa_api" {
  source = "./modules/review-spa-api"
  providers = {
    aws.global = aws.use1
  }

  api_domain         = var.review_spa_api_domain
  cdn_domain         = var.review_spa_cdn_domain
  route53_zone_id    = data.aws_route53_zone.review_spa_zone.zone_id
  function_name      = "${var.review_spa_app_name}-api"
  cf_distribution_id = module.review_spa_cdn.cf_distribution_id
  origin_bucket_name = module.review_spa_cdn.origin_bucket_name
}
