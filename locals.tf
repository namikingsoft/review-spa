locals {
  route53_zone_name          = var.route53_zone_name[terraform.workspace]
  resource_name_prefix       = var.resource_name_prefix[terraform.workspace]
  api_domain                 = var.api_domain[terraform.workspace]
  cdn_domain                 = var.cdn_domain[terraform.workspace]
  cdn_token_name             = var.cdn_token_name[terraform.workspace]
  cdn_token_max_age          = var.cdn_token_max_age[terraform.workspace]
  cdn_settings_json_filename = var.cdn_settings_json_filename[terraform.workspace]
  github_oauth_client_id     = var.github_oauth_client_id[terraform.workspace]
  github_oauth_client_secret = var.github_oauth_client_secret[terraform.workspace]
}
