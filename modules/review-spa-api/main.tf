data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "/tmp/${basename(path.module)}/lambda.zip"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.origin_bucket_name}",
      "arn:aws:s3:::${var.origin_bucket_name}/*",
      "arn:aws:s3:::${aws_s3_bucket.temp_archive.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.temp_archive.bucket}/*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetDistribution",
      "cloudfront:GetInvalidation",
      "cloudfront:GetStreamingDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudfront:ListInvalidations",
      "cloudfront:ListStreamingDistributions",
    ]

    resources = [
      # TODO: filter distribution
      "*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:*"
    ]

    resources = [
      aws_dynamodb_table.temp_archive.arn,
    ]
  }
}

data "aws_iam_policy_document" "api_gateway_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "api_gateway" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

module "lambda_iam_role" {
  source = "../lambda-iam-role"

  role_name = "${var.resource_name_prefix}-lambda"
}

module "api_acm" {
  source = "../acm-certificate"
  providers = {
    aws.global = aws.global
  }

  domain_name     = var.api_domain
  route53_zone_id = var.route53_zone_id
}

module "api_dns" {
  source = "../route53-alias"

  name                   = var.api_domain
  target                 = aws_api_gateway_domain_name.api.cloudfront_domain_name
  route53_zone_id        = var.route53_zone_id
  route53_hosted_zone_id = aws_api_gateway_domain_name.api.cloudfront_zone_id
  tag_name               = "terraform"
}

resource "aws_lambda_function" "entry" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.resource_name_prefix}-entry"
  role             = module.lambda_iam_role.arn
  handler          = "entry.lambda_handler"
  runtime          = "python3.8"
  timeout          = 30
  source_code_hash = filebase64sha256("${data.archive_file.lambda.output_path}")
  publish          = "true"

  environment {
    variables = {
      CDN_WILDCARD_DOMAIN      = var.cdn_domain
      TEMP_ARCHIVE_BUCKET_NAME = aws_s3_bucket.temp_archive.bucket
      TEMP_ARCHIVE_TABLE_NAME  = aws_dynamodb_table.temp_archive.name
    }
  }
}

resource "aws_lambda_function" "deploy" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.resource_name_prefix}-deploy"
  role             = module.lambda_iam_role.arn
  handler          = "deploy.lambda_handler"
  runtime          = "python3.8"
  timeout          = 30
  source_code_hash = filebase64sha256("${data.archive_file.lambda.output_path}")
  publish          = "true"

  environment {
    variables = {
      ORIGIN_BUCKET_NAME       = var.origin_bucket_name
      CF_DISTRIBUTION_ID       = var.cf_distribution_id
      TEMP_ARCHIVE_BUCKET_NAME = aws_s3_bucket.temp_archive.bucket
      TEMP_ARCHIVE_TABLE_NAME  = aws_dynamodb_table.temp_archive.name
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.api_domain} API"
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name     = var.api_domain
  certificate_arn = module.api_acm.acm_certification_arn
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "live"

  depends_on = [aws_api_gateway_integration.api]
}

resource "aws_api_gateway_method_settings" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_deployment.api.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }

  depends_on = [aws_api_gateway_account.api]
}

resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = aws_iam_role.api.arn
}

resource "aws_iam_role" "api" {
  name =  "${var.resource_name_prefix}-api-gateway"

  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume.json
}

resource "aws_iam_role_policy" "api" {
  name = "default"
  role = aws_iam_role.api.id

  policy = data.aws_iam_policy_document.api_gateway.json
}

resource "aws_lambda_permission" "api" {
  function_name = aws_lambda_function.entry.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/${aws_api_gateway_deployment.api.stage_name}/*/*"
  depends_on    = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api]
}

resource "aws_lambda_permission" "api-base" {
  function_name = aws_lambda_function.entry.function_name
  statement_id  = "AllowExecutionFromApiGatewayBase"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/${aws_api_gateway_deployment.api.stage_name}"
  depends_on    = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api]
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.resource_name_prefix}-lambda-policy"
  role   = module.lambda_iam_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_method.api.resource_id
  http_method             = aws_api_gateway_method.api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.entry.invoke_arn
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_deployment.api.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

resource "aws_dynamodb_table" "temp_archive" {
  name           = "${var.resource_name_prefix}-archive"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "Key"

  attribute {
    name = "Key"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }
}

resource "aws_s3_bucket" "temp_archive" {
  bucket = "${var.resource_name_prefix}-archive"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 1
    }
  }

  force_destroy = true
}

resource "aws_s3_bucket_notification" "temp_archive" {
  bucket = aws_s3_bucket.temp_archive.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.deploy.arn
    events              = ["s3:ObjectCreated:Put"]
  }
}

resource "aws_lambda_permission" "temp_archive" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deploy.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.temp_archive.arn
}
