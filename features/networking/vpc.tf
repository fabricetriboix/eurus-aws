locals {
  public_subnets = [
    for i in var.availability_zones :
    cidrsubnet(var.cidr, var.public_subnet_bits, i)
  ]

  private_subnets = [
    for i in var.availability_zones :
    cidrsubnet(var.cidr, var.private_subnet_bits, i + 8)
  ]

  db_subnets = [
    for i in var.availability_zones :
    cidrsubnet(var.cidr, var.db_subnet_bits, i + 16)
  ]

  # "Internal subnets" don't have any routes to go outside.
  internal_subnets = [
    for i in var.availability_zones :
    cidrsubnet(var.cidr, var.internal_subnet_bits, i + 24)
  ]
}

module "vpc" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:No tags yet in `terraform-aws-vpc`
  source = "git::https://github.com/fabricetriboix/terraform-aws-vpc.git?ref=master"

  name             = var.env
  cidr             = var.cidr
  azs              = var.availability_zones
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.db_subnets
  intra_subnets    = local.internal_subnets

  create_igw         = true
  enable_nat_gateway = true

  enable_dns_hostnames         = true
  enable_dns_support           = true
  enable_flow_log              = false
  enable_ipv6                  = false
  create_database_subnet_group = true
}
