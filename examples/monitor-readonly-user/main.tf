terraform {
  required_version = "> 0.12.0"
  required_providers {
    aws = "~> 2.33.0"
    template = "~> 2.1.2"
    null = "~> 2.1.2"
  }
}

provider "aws" {
  region  = "eu-west-1"
  version = "1.24.0"
}

provider "template" {
  version = "1.0"
}

module "account_setup" {
  source = "../../"

  enable_monitor_readonly_user = true
  monitor_readonly_user_name   = "example-monitor-readonly"
}
