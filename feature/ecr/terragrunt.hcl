# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.version: The version of the feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.retention_in_days: How many days to keep the images; set to 0 to keep indefinitely

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-ecr"
  enabled   = try(values.enabled, false)

  # Both the `prod` and `nonprod` ECRs allow images from the `common-nonprod` account only to be pushed to them.
  source_account_ids = [
    for id in split(",", get_env("COMMON_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
  ]

  # Any account can pull images from the `prod` ECR, but only `nonprod` accounts can pull images from the `nonprod` ECR
  pull_account_ids = values.realm == "prod" ?
    concat([
      for id in split(",", get_env("COMMON_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
    ], [
      for id in split(",", get_env("COMMON_PROD_ACCOUNT_IDS", "")) : trimspace(id)
    ], [
      for id in split(",", get_env("APP_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
    ], [
      for id in split(",", get_env("APP_PROD_ACCOUNT_IDS", "")) : trimspace(id)
    ])
    : concat([
      for id in split(",", get_env("COMMON_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
    ], [
      for id in split(",", get_env("APP_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
    ])
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
  source_account_ids = local.source_account_ids
  pull_account_ids   = local.pull_account_ids
  retention_in_days  = values.retention_in_days
}
