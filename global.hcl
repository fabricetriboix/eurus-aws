# The including file must define the following:
#
#   var.account_type - eg: `common` or `app`
#   var.realm        - eg: `nonprod` or `prod`
#   var.env          - environment name, eg: `dev`, `stg`, `prd`, etc.
#   var.unit_name    - Terragrunt unit name, typically the name of a feature, eg: `networking`, `observability`, etc.

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
        bucket         = "${local.org}-${local.project}-tf-${var.account_type}-${var.realm}"
        key            = "${var.env}/${var.unit_name}/tofu.tfstate"
        region         = "${local.region}"
        encrypt        = true
        dynamodb_table = "${local.org}-${local.project}-${var.account_type}-${var.realm}-tf-locks"
      }
    }
EOF
}
