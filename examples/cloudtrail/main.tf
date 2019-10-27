terraform {
  required_version = ">= 0.12.12"
  required_providers {
    aws = "~> 2.33.0"
    template = "~> 2.1.2"
    null = "~> 2.1.2"
  }
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 2.33.0"
  profile = "my-aws-profile"
}

provider "template" {
  version = "~> 2.1.2"
}

module "account_setup" {
  source = "../../"

  # Cloudtrail (optional)
  enable_cloudtrail        = true
  cloudtrail_bucket_region = "eu-west-1"
  trail_name               = "my-account-trail"
}
