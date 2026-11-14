# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.version: The version of the feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.region_cfgs[*].cidr: CIDR for the VPC
#     values.region_cfgs[*].secondary_cidrs: List of secondary CIDRs, if any
#     values.region_cfgs[*].enable_dhcp_options: Boolean
#     values.region_cfgs[*].dhcp_options_domain_name: Domain suffix for resolving non-FQDNs
#     values.region_cfgs[*].dhcp_options_domain_name_servers: List of name servers to configure via DHCP
#     values.region_cfgs[*].dhcp_options_ntp_servers: List of NTP servers to configure via DHCP
#     values.region_cfgs[*].dhcp_options_netbios_name_servers: List of NETBIOS name servers
#     values.region_cfgs[*].dhcp_options_netbios_node_type: The NetBIOS node type (1, 2, 4, or 8)
#     values.region_cfgs[*].availability_zones: List of availability zones (minimum 2)
#     values.region_cfgs[*].egress_subnets: List of CIDRs for the egress subnets (if any)
#     values.region_cfgs[*].platform_subnets: List of CIDRs for the platform subnets
#     values.flow_logs_cfg.enabled: Boolean
#     values.flow_logs_cfg.retention_days: How many days to retain the flow logs
#
# NB: Exactly two regions must be passed in the `values.region_cfgs` list. The
#     first item is the primary region and the second item is the secondary
#     region.

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-networking"
  enabled   = try(values.enabled, true)
  region1   = include.global.locals.region1
  region2   = include.global.locals.region2
  tf_bucket = "${include.global.locals.tf_bucket_prefix}-${values.account_type}-${values.realm}-${local.region1}-tf"
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
        bucket       = "${local.tf_bucket}"
        key          = "${values.env}/${local.unit_name}/tofu.tfstate"
        region       = "${local.region1}"
        encrypt      = true
        use_lockfile = true
      }
    }
EOF
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.17.0"
    }
  }
}

provider "aws" {
  alias  = "region1"
  region = "${include.global.locals.region1}"

  default_tags = {
    tags = {
      FeatureSource  = "feature/networking"
      FeatureVersion = "${values.version}"
      Organisation   = "${values.org}"
      Project        = "${values.project}"
      Region         = "${include.global.locals.region1}"
      Environment    = "${values.env}"
      ManagedBy      = "OpenTofu"
    }
  }
}

provider "aws" {
  alias  = "region2"
  region = "${include.global.locals.region2}"

  default_tags = {
    tags = {
      FeatureSource  = "feature/networking"
      FeatureVersion = "${values.version}"
      Organisation   = "${values.org}"
      Project        = "${values.project}"
      Region         = "${include.global.locals.region2}"
      Environment    = "${values.env}"
      ManagedBy      = "OpenTofu"
    }
  }
}

%{ for i, r in values.regions }
module "region${i + 1}" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git//?ref=xxx"
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//module/networking?ref=feat-networking-mr" 

  providers {
    aws = aws.region${i + 1}
  }

  org           = "${values.org}"
  project       = "${values.project}"
  region        = i == 0 ? "${include.global.locals.region1}" : "${include.global.locals.region2}"
  env           = "${values.env}"
  cfg           = var.region_cfgs[${i}]
  flow_logs_cfg = var.flow_logs_cfg
}
%{ endfor }
EOF
}

terraform {
  source = "."
}

inputs = {
  region_cfgs   = values.region_cfgs
  flow_logs_cfg = values.flow_logs_cfg
}
