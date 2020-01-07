data "archive_file" "lambda_at_edge" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_at_edge"
  output_path = "/tmp/${basename(path.module)}/lambda_at_edge.zip"
}

module "iam_role" {
  source = "../lambda-iam-role"

  function_name = var.function_name
}

resource "aws_lambda_function" "urlrewrite" {
  provider = aws.global

  filename         = data.archive_file.lambda_at_edge.output_path
  function_name    = var.function_name
  role             = module.iam_role.arn
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  source_code_hash = filebase64sha256("${data.archive_file.lambda_at_edge.output_path}")
  publish          = "true"
}
