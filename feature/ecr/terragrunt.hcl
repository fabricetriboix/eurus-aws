# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.version: The version of the feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.source_account_ids: IDs of the accounts that can create repositories and push images into this ECR
#     values.retention_in_days: How many days to keep the images; set to 0 to keep indefinitely

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-ecr"
  enabled   = try(values.enabled, false)
}

exclude {
  if      = !local.enabled
  actions = ["plan", "apply"]
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
  feature_version    = values.version
  org                = include.global.locals.org
  project            = include.global.locals.project
  region             = include.global.locals.region
  env                = values.env
  source_account_ids = values.source_account_ids
  pull_account_ids   = values.pull_account_ids
  retention_in_days  = values.retention_in_days
}
