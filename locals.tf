locals {
  route53_zone_name            = var.route53_zone_name[terraform.workspace]
  resource_name_prefix         = var.resource_name_prefix[terraform.workspace]
  review_spa_api_domain        = var.review_spa_api_domain[terraform.workspace]
  review_spa_cdn_domain        = var.review_spa_cdn_domain[terraform.workspace]
  review_spa_cdn_token_name    = var.review_spa_cdn_token_name[terraform.workspace]
  review_spa_cdn_token_max_age = var.review_spa_cdn_token_max_age[terraform.workspace]
  github_oauth_client_id       = var.github_oauth_client_id[terraform.workspace]
  github_oauth_client_secret   = var.github_oauth_client_secret[terraform.workspace]
}
