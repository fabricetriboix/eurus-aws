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

# Default AWS provider: target the management account
provider "aws" {
  region = "${include.global.locals.regions[0]}"

  default_tags {
    tags = {
      Realm        = "management"
      AccountType  = "management"
      Organisation = "${include.global.locals.org}"
      Project      = "${include.global.locals.project}"
      Region       = "${include.global.locals.regions[0]}"
      Source       = "bootstrap"
      Tenant       = "Platform"
      CostCenter   = "1001"
    }
  }
}

%{ for account_name, account in include.accounts.locals.accounts }
%{ for region in include.global.locals.regions }
provider "aws" {
  alias  = "${account_name}-${region}"
  region = "${region}"

  assume_role {
    role_arn = "arn:aws:iam::${account.id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Realm        = "${account.realm}"
      AccountType  = "${account.type}"
      Organisation = "${include.global.locals.org}"
      Project      = "${include.global.locals.project}"
      Region       = "${region}"
      Source       = "bootstrap"
      Tenant       = "Platform"
      CostCenter   = "1001"
    }
  }
}
%{ endfor }
%{ endfor }
EOF
}

generate "bootstrap" {
  path      = "bootstrap.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
%{ for account_name, account in include.accounts.locals.accounts }
%{ for region in include.global.locals.regions }
module "bootstrap_${account_name}_${region}" {

  providers = {
    aws = aws.${account_name}-${region}
  }

  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/eurus-aws.git?ref=module-bootstrap-v1.1.1"

  org                        = "${include.global.locals.org}"
  project                    = "${include.global.locals.project}"
  region                     = "${region}"
  realm                      = "${account.realm}"
  account_type               = "${account.type}"
  account_name               = "${account_name}"
  management_github_role_arn = aws_iam_role.github_actions_role.arn
}
%{ endfor }
%{ endfor }
EOF
}

inputs = {
  regions  = include.global.locals.regions
  accounts = include.accounts.locals.accounts
}
