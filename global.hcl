# The including file must define the following:
#
#   local.account_type - eg: `common` or `app`
#   local.realm        - eg: `nonprod` or `prod`
#   local.env          - environment name, eg: `dev`, `stg`, `prd`, etc.
#   local.unit_name    - Terragrunt unit name, typically the name of a feature, eg: `networking`, `observability`, etc.

locals {
  region  = "eu-west-1"
  org     = "myorg"
  project = "myproject"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "s3" {
        bucket         = "${local.org}-${local.project}-tf-${local.account_type}-${local.realm}"
        key            = "${local.env}/${local.unit_name}/tofu.tfstate"
        region         = "${local.region}"
        encrypt        = true
        dynamodb_table = "${local.org}-${local.project}-${local.account_type}-${local.realm}-tf-locks"
      }
    }
EOF
}
