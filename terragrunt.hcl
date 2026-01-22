include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

generate "aws_provider" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.17.0"
    }
  }
}

provider "aws" {
  region = "${include.global.locals.region}"

  default_tags {
    tags = {
      Realm      = "nonprod"
      Source     = "bootstrap/common-nonprod"
      Tenant     = "Platform"
      CostCenter = "1001"
    }
  }
}
EOF
}
