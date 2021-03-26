terraform {
  required_version = ">= 0.12.12"
  required_providers {
    aws = "~> 2.33.0"
    template = "~> 2.1.2"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "my-aws-profile"
}

module "account_setup" {
  source = "../../"

  enable_read_only_group = true

  // Optional
  read_only_group_name = "read-only-group"
}
