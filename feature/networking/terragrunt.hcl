include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

terraform {
  source = "github.com/${values.github_org}/${values.github_repo}?ref=features/networking/v0.2.0"
}

inputs = {
  env                  = values.env
  cidr                 = values.cidr
  availability_zones   = values.availability_zones
  public_subnet_bits   = values.public_subnet_bits
  private_subnet_bits  = values.private_subnet_bits
  db_subnet_bits       = values.db_subnet_bits
  internal_subnet_bits = values.internal_subnet_bits
}
