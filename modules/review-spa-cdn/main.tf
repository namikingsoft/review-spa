data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.origin_bucket_name}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_origin.iam_arn]
    }
  }
}

data "archive_file" "lambda_at_edge" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "/tmp/${basename(path.module)}/lambda.zip"
}

module "iam_role" {
  source = "../lambda-iam-role"

  function_name = var.function_name
}

module "cdn_acm" {
  source = "../acm-certificate"
  providers = {
    aws.global = aws.global
  }

  domain_name     = var.wildcard_domain
  route53_zone_id = var.route53_zone_id
}

module "cdn_dns" {
  source = "../route53-alias"

  name                   = var.wildcard_domain
  target                 = aws_cloudfront_distribution.cdn.domain_name
  route53_zone_id        = var.route53_zone_id
  route53_hosted_zone_id = aws_cloudfront_distribution.cdn.hosted_zone_id
  tag_name               = "terraform"
}

resource "aws_cloudfront_origin_access_identity" "s3_origin" {
  comment = "${var.origin_bucket_name} of s3 bucket"
}

resource "aws_s3_bucket" "origin" {
  bucket = var.origin_bucket_name

  versioning {
    enabled = false
  }

  force_destroy = true
}

resource "aws_s3_bucket_policy" "origin" {
  bucket = aws_s3_bucket.origin.id
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.origin.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.origin.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_origin.cloudfront_access_identity_path
    }
  }

  enabled = true
  comment = var.comment

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.origin.id
    compress         = true

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.urlrewrite.qualified_arn
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = var.default_ttl
    max_ttl                = 31536000
  }

  price_class = "PriceClass_200"

  aliases = [var.wildcard_domain]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    bucket = var.logging_bucket_name
  }

  viewer_certificate {
    acm_certificate_arn      = module.cdn_acm.acm_certification_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}

resource "aws_lambda_function" "urlrewrite" {
  provider = aws.global

  filename         = data.archive_file.lambda_at_edge.output_path
  function_name    = var.function_name
  role             = module.iam_role.arn
  handler          = "urlrewrite.handler"
  runtime          = "nodejs10.x"
  source_code_hash = filebase64sha256("${data.archive_file.lambda_at_edge.output_path}")
  publish          = "true"
}
