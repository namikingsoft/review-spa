data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "/tmp/${basename(path.module)}/lambda.zip"
}

data "aws_iam_policy_document" "s3" {
  count = length(var.bucket_ids)

  statement {
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_ids[count.index]}",
      "arn:aws:s3:::${var.bucket_ids[count.index]}/*",
    ]
  }
}

data "aws_s3_bucket" "loggings" {
  count = length(var.bucket_ids)

  bucket = var.bucket_ids[count.index]
}

module "iam_role" {
  source = "../lambda-iam-role"

  function_name = var.function_name
}

resource "aws_lambda_function" "to_partition" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.function_name
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  source_code_hash = filebase64sha256("${data.archive_file.lambda.output_path}")
  publish          = "true"
  role             = module.iam_role.arn
}

resource "aws_s3_bucket_notification" "loggings" {
  count = length(var.bucket_ids)

  bucket = var.bucket_ids[count.index]

  lambda_function {
    lambda_function_arn = aws_lambda_function.to_partition.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = ".gz"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  count = length(var.bucket_ids)

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.to_partition.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.loggings[count.index].arn
}

resource "aws_iam_role_policy" "s3" {
  count = length(var.bucket_ids)

  role   = module.iam_role.id
  name   = "${var.function_name}-s3-${var.bucket_ids[count.index]}"
  policy = data.aws_iam_policy_document.s3[count.index].json
}
