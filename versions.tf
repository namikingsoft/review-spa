terraform {
  required_version = ">= 0.12"

  backend "s3" {
    # NOTE: input on terrform init
    # bucket = "review-spa-tfstate"
    # key    = "terraform.tfstate"
    # region = "ap-northeast-1"
  }
}

provider "aws" {
  version = "~> 2.44.0"
}

provider "aws" {
  # for acm via cloudfront
  region = "us-east-1"
  alias  = "use1"
}

provider "archive" {
  version = "~> 1.3.0"
}
