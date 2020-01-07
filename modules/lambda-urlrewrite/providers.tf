provider "aws" {
  # CloudFront で使うリソースは現状 us-east-1 に配置する必要がある
  alias = "global"
}
