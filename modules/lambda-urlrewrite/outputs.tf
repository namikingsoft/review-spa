output "lambda_arn" {
  value = aws_lambda_function.urlrewrite.qualified_arn
}
