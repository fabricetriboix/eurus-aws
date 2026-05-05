# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-grafana"
  enabled   = try(values.enabled, true)
}

exclude {
  if     = !local.enabled
  actions = ["all"]
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
  org     = include.global.locals.org
  project = include.global.locals.project
  env     = values.env
}
