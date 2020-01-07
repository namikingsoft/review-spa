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

resource "aws_cloudfront_origin_access_identity" "s3_origin" {
  comment = "${var.origin_bucket_name} of s3 bucket"
}

resource "aws_s3_bucket" "origin" {
  bucket = var.origin_bucket_name

  versioning {
    enabled = true
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

    dynamic "lambda_function_association" {
      for_each = var.lambda_arns
      iterator = lambda_arn

      content {
        event_type = "viewer-request"
        lambda_arn = lambda_arn.value
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = var.default_ttl
    max_ttl                = 31536000
  }

  price_class = "PriceClass_200"

  aliases = var.aliases

  # for browser history 
  # custom_error_response {
  #   error_code            = 403
  #   error_caching_min_ttl = 300 # default
  #   response_code         = 200
  #   response_page_path    = "/index.html"
  # }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    bucket = var.logging_bucket_name
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}
