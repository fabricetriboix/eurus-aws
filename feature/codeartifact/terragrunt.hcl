# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.version: The version of the feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.public_repositories: List of public repositories, eg: ["npmjs", "pypi", "nuget-org", "maven-central", "maven-googleandroid", "maven-gradleplugins", "maven-commonsware", "maven-clojars", "ruby-gems-org", "crates-io"]
#     values.internal_formats: List of AWS CodeArtifact formats to manage internally, eg: ["npm", "pypi", "maven", "nuget", "generic", "ruby", "swift", "cargo"]
#     values.internal_packages_namespace: Namespace (or package name prefix) for internal packages (optional)
#     values.internal_maven_namespace: Namespace for internal Maven packages (optional)

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-codeartifact"
  enabled   = try(values.enabled, false)

  # All `non-prod` accounts must be able to pull from CodeArtifact, but `prod` accounts should not because `prod` accounts don't build anything
  codeartifact_read_account_ids = compact(concat([
    for id in split(",", get_env("COMMON_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
  ], [
    for id in split(",", get_env("APP_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)

  ]))
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
  feature_version             = values.version
  org                         = include.global.locals.org
  project                     = include.global.locals.project
  region                      = include.global.locals.region
  realm                       = values.realm
  env                         = values.env
  public_repositories         = try(values.public_repositories, [])
  internal_formats            = try(values.internal_formats, [])
  internal_packages_namespace = try(values.internal_packages_namespace, null)
  internal_maven_namespace    = try(values.internal_maven_namespace, null)
  accounts_with_pull_access   = local.codeartifact_read_account_ids
}
