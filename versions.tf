terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket = "review-for-spa-tfstate"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  version = "~> 2.13.0"
}

provider "aws" {
  # for acm via cloudfront
  region = "us-east-1"
  alias  = "use1"
}

provider "archive" {
  version = "~> 1.2.2"
}
