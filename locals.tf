locals {
  route53_zone_name = "namiking.net."

  review_for_spa_app_name            = "review-for-spa"
  review_for_spa_app_domain          = "*.review-for-spa.namiking.net"
  review_for_spa_api_domain          = "api-review-for-spa.namiking.net"
  review_for_spa_logging_bucket_name = "review-for-spa-logging"
  review_for_spa_default_ttl         = 604800

  to_partition_function_name = "copy-log-to-partition-for-athena"
}
