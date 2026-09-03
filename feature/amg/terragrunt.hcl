# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.version: The version of the feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.logs_retention_days: Number of days to retain logs for the `datasrc` Lambda function
#     values.data_source_account_ids: List of IDs of the AWS accounts that are allowed to create data sources in Amazon Grafana

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-amg"
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
  feature_version         = values.version
  org                     = include.global.locals.org
  project                 = include.global.locals.project
  region                  = include.global.locals.region
  env                     = values.env
  logs_retention_days     = values.logs_retention_days
  data_source_account_ids = values.data_source_account_ids
}
