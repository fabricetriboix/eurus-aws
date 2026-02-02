# Required values:
#
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.cidr: CIDR for the VPC
#     values.availability_zones
#     values.public_subnets
#     values.private_subnets
#     values.db_subnets
#     values.internal_subnets

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-networking"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "s3" {
        bucket       = "${include.global.locals.org}-${include.global.locals.project}-${values.account_type}-${values.realm}-tf"
        key          = "${values.env}/${local.unit_name}/tofu.tfstate"
        region       = "${include.global.locals.region}"
        encrypt      = true
        use_lockfile = true
      }
    }
EOF
}

terraform {
  source = "."
}

inputs = {
  env                = values.env
  cidr               = values.cidr
  availability_zones = values.availability_zones
  public_subnets     = values.public_subnets
  private_subnets    = values.private_subnets
  db_subnets         = values.db_subnets
  internal_subnets   = values.internal_subnets
}
