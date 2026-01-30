include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

terraform {
  source = "github.com/${values.github_org}/${values.github_repo}?ref=features/networking/v0.2.0"
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
