locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global-vars.hcl"))
  github_org  = local.global_vars.locals.github_org
  github_repo = local.global_vars.locals.github_repo
}

include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

terraform {
  source = "github.com/${local.github_org}/${local.github_repo}?ref=v0.1.0"
}
