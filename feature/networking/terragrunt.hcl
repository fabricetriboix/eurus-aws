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
  cwd               = get_terragrunt_dir()
  cwd_segments      = split("/", cwd)
  last_two_segments = slice(local.cwd_segments, length(local.cwd_segments) - 2, length(local.cwd_segments))
  unit_name         = join("-", local.last_two_segments)
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "s3" {
        bucket         = "${local.org}-${local.project}-tf-${values.account_type}-${values.realm}"
        key            = "${values.env}/${local.unit_name}/tofu.tfstate"
        region         = "${local.region}"
        encrypt        = true
        dynamodb_table = "${local.org}-${local.project}-${var.account_type}-${var.realm}-tf-locks"
      }
    }
EOF

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
