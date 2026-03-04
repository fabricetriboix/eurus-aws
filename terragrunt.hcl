include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

include "accounts" {
  path   = "accounts.hcl"
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
      Realm       = "management"
      AccountType = "management"
      Source      = "bootstrap"
      Tenant      = "Platform"
      CostCenter  = "1001"
    }
  }
}

%{ for account_name, account in include.accounts.locals.accounts }
provider "aws" {
  alias  = "${account_name}"
  region = "${include.global.locals.region}"

  assume_role {
    role_arn = "arn:aws:iam::${account.id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Realm       = "${account.realm}"
      AccountType = "${account.type}"
      Source      = "bootstrap"
      Tenant      = "Platform"
      CostCenter  = "1001"
    }
  }
}
%{ endfor }
EOF
}

generate "bootstrap" {
  path      = "bootstrap.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
%{ for account_name, account in include.accounts.locals.accounts }
module "bootstrap_${account_name}" {

  providers = {
    aws = aws.${account_name}
  }

  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git?ref=module-bootstrap-v0.2.1"
  source = "../../module/bootstrap"

  org                        = "${include.global.locals.org}"
  project                    = "${include.global.locals.project}"
  region                     = "${include.global.locals.region}"
  realm                      = "${account.realm}"
  account_id                 = "${account.id}"
  account_type               = "${account.type}"
  management_github_role_arn = aws_iam_role.github_actions_role.arn
}
%{ endfor }
EOF
}

inputs = {
  region   = include.global.locals.region
  accounts = include.accounts.locals.accounts
}
