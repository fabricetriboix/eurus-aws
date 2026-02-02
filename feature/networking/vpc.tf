module "vpc" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-vpc.git?ref=master"

  name             = var.env
  cidr             = var.cidr
  azs              = var.availability_zones
  public_subnets   = coalesce(var.public_subnets, [])
  private_subnets  = coalesce(var.private_subnets, [])
  database_subnets = coalesce(var.db_subnets, [])
  intra_subnets    = coalesce(var.internal_subnets, [])

  create_igw         = true
  enable_nat_gateway = true

  enable_dns_hostnames         = true
  enable_dns_support           = true
  enable_flow_log              = false
  enable_ipv6                  = false
  create_database_subnet_group = true
}
