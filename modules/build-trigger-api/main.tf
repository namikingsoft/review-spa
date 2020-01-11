data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "/tmp/${basename(path.module)}/lambda.zip"
}

data "aws_iam_policy_document" "s3_public" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.temp_archive.bucket}/*",
    ]
  }
}

data "aws_iam_policy_document" "s3_by_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.temp_archive.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.temp_archive.bucket}/*",
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

module "iam_role" {
  source = "../lambda-iam-role"

  function_name = var.function_name
}

module "api_acm" {
  source = "../acm-certificate"
  providers = {
    aws.global = aws.global
  }

  domain_name     = var.domain
  route53_zone_id = var.route53_zone_id
}

module "api_dns" {
  source = "../route53-alias"

  name                   = var.domain
  target                 = aws_api_gateway_domain_name.api.cloudfront_domain_name
  route53_zone_id        = var.route53_zone_id
  route53_hosted_zone_id = aws_api_gateway_domain_name.api.cloudfront_zone_id
  tag_name               = "terraform"
}

resource "aws_s3_bucket" "temp_archive" {
  bucket = var.temp_archive_bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_policy" "temp_archive_policy" {
  bucket = aws_s3_bucket.temp_archive.id
  policy = data.aws_iam_policy_document.s3_public.json
}

resource "aws_lambda_function" "api" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.function_name
  role             = module.iam_role.arn
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  timeout          = 30
  source_code_hash = filebase64sha256("${data.archive_file.lambda.output_path}")
  publish          = "true"

  environment {
    variables = {
      tempArchiveBucketName = aws_s3_bucket.temp_archive.bucket
      tempArchiveDomainName = aws_s3_bucket.temp_archive.bucket_regional_domain_name
      circleCIPersonalToken = var.circle_token
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.domain} API"
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
  domain_name     = var.domain
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
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume.json
}

resource "aws_iam_role_policy" "api" {
  name = "default"
  role = aws_iam_role.api.id

  policy = data.aws_iam_policy_document.api_gateway.json
}

resource "aws_lambda_permission" "api" {
  function_name = aws_lambda_function.api.function_name
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/${aws_api_gateway_deployment.api.stage_name}/*/*"
  depends_on    = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api]
}

resource "aws_lambda_permission" "api-base" {
  function_name = aws_lambda_function.api.function_name
  statement_id  = "AllowExecutionFromApiGatewayBase"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/${aws_api_gateway_deployment.api.stage_name}"

  depends_on    = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api]
}

resource "aws_iam_role_policy" "s3" {
  role   = module.iam_role.id
  name   = "${var.function_name}-s3"
  policy = data.aws_iam_policy_document.s3_by_lambda.json
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_method.api.resource_id
  http_method             = aws_api_gateway_method.api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_deployment.api.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}