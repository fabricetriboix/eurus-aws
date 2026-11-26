# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.version: The version of the feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.region: Region where this feature is deployed
#     values.cidr: CIDR for the VPC
#     values.secondary_cidrs: List of secondary CIDRs, if any
#     values.enable_dhcp_options: Boolean
#     values.dhcp_options_domain_name: Domain suffix for resolving non-FQDNs
#     values.dhcp_options_domain_name_servers: List of name servers to configure via DHCP
#     values.dhcp_options_ntp_servers: List of NTP servers to configure via DHCP
#     values.dhcp_options_netbios_name_servers: List of NETBIOS name servers
#     values.dhcp_options_netbios_node_type: The NetBIOS node type (1, 2, 4, or 8)
#     values.egress_subnets: List of CIDRs for the egress subnets (if any)
#     values.platform_subnets: List of CIDRs for the platform subnets
#     values.enable_flow_logs: Boolean
#     values.flow_logs_retention_days How many days to retain the flow logs
#
# NB: The lists of availability zones, egress subnets (if present) and platform
#     subnets must be of equal length and in the same order.

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-networking"
  enabled   = try(values.enabled, true)
  tf_bucket = "${include.global.locals.tf_bucket_prefix}-${values.account_type}-${values.realm}-${values.env}-${values.region}-tf"
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
        key          = "${local.unit_name}/tofu.tfstate"
        region       = "${values.region}"
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
  feature_version                   = values.version
  org                               = include.global.locals.org
  project                           = include.global.locals.project
  region                            = values.region
  realm                             = values.realm
  account_type                      = values.account_type
  env                               = values.env
  cidr                              = values.cidr
  secondary_cidrs                   = values.secondary_cidrs
  enable_dhcp_options               = values.enable_dhcp_options
  dhcp_options_domain_name          = values.dhcp_options_domain_name
  dhcp_options_domain_name_servers  = values.dhcp_options_domain_name_servers
  dhcp_options_ntp_servers          = values.dhcp_options_ntp_servers
  dhcp_options_netbios_name_servers = values.dhcp_options_netbios_name_servers
  dhcp_options_netbios_node_type    = values.dhcp_options_netbios_node_type
  egress_subnets                    = values.egress_subnets
  platform_subnets                  = values.platform_subnets
  enable_flow_logs                  = values.enable_flow_logs
  flow_logs_retention_days          = values.flow_logs_retention_days
}
