include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  children_account_ids = split(",", get_env("CHILDREN_ACCOUNT_IDS"))
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

%{ for account_id in local.children_account_ids }
provider "aws" {
  alias  = "aws-${account_id}"
  region = "${include.global.locals.region}"

  assume_role {
    role_arn = "arn:aws:iam::${account_id}:role/OrganizationAccountAccessRole"
  }
}
%{ endfor }
EOF
}

inputs = {
  children_account_ids = local.children_account_ids
}
