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

  enable_aws_config                    = true
  enable_account_password_policy       = false
  enable_admin_group                   = false
  enable_mfa                           = false
  aws_config_notification_emails       = ["test@example.com"]
  tag1Key                              = "Project"
  enable_rule_require_tag              = true
  enable_rule_require_root_account_MFA = true
  enable_rule_require_cloud_trail      = true
  enable_rule_iam_password_policy      = true
}
