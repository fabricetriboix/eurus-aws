# Required values:
#
#     values.enabled: Whether to enable or disable this feature
#     values.account_type: Type of AWS account, either "common" or "app"
#     values.realm: Either `nonprod` or `prod`
#     values.env: Name of the environment, eg: `dev`, `stg`, `prd`
#     values.cidr: CIDR for the VPC
#     values.secondary_cidrs: List of secondary CIDRs, if any
#     values.enable_dhcp_options: Boolean
#     values.dhcp_options_domain_name: Domain suffix for resolving non-FQDNs
#     values.dhcp_options_domain_name_servers: List of name servers to configure via DHCP
#     values.dhcp_options_ntp_servers: List of NTP servers to configure via DHCP
#     values.dhcp_options_netbios_name_servers: List of NETBIOS name servers
#     values.dhcp_options_netbios_node_type: The NetBIOS node type (1, 2, 4, or 8)
#     values.availability_zones: List of availability zones (minimum 2)
#     values.egress_subnets: List of CIDRs for the egress subnets
#     values.enable_flow_logs: Boolean
#     values.flow_log_retention_days: How many days to retain the flow logs

include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  unit_name = "feature-networking"
  enabled   = try(values.enabled, true)
}

exclude {
  if     = !local.enabled
  actions = ["all"]
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
  org                               = include.global.locals.org
  project                           = include.global.locals.project
  env                               = values.env
  cidr                              = values.cidr
  secondary_cidrs                   = values.secondary_cidrs
  enable_dhcp_options               = values.enable_dhcp_options
  dhcp_options_domain_name          = values.dhcp_options_domain_name
  dhcp_options_domain_name_servers  = values.dhcp_options_domain_name_servers
  dhcp_options_ntp_servers          = values.dhcp_options_ntp_servers
  dhcp_options_netbios_name_servers = values.dhcp_options_netbios_name_servers
  dhcp_options_netbios_node_type    = values.dhcp_options_netbios_node_type
  availability_zones                = values.availability_zones
  egress_subnets                    = values.egress_subnets
  enable_flow_logs                  = values.enable_flow_logs
  flow_log_retention_days           = values.flow_log_retention_days
}
