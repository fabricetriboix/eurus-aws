include "global_vars" {
  path   = find_in_parent_folders("global-vars.hcl")
  expose = true
}

locals {
  github_org  = include.global_vars.locals.github_org
  github_repo = include.global_vars.locals.github_repo
}

include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

terraform {
  source = "github.com/${local.github_org}/${local.github_repo}?ref=features/networking/v0.2.0"
}
