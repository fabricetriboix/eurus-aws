locals {
  account_type = values.account_type
  realm        = values.realm
  env          = values.env
  unit_name    = "feature-networking"
}

include "global" {
  # NB: This also defines the backend
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

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
