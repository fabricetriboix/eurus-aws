locals {
  config = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

unit "networking" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git//feature/networking?ref=feat-tg-networking"
  source = "../../../feature/networking"

  path = "feature-networking"

  values = {
    enabled                           = local.config.features.networking.enabled
    account_type                      = local.config.account_type
    realm                             = local.config.realm
    env                               = local.config.env
    cidr                              = local.config.features.networking.cidr
    secondary_cidrs                   = local.config.features.networking.secondary_cidrs
    enable_dhcp_options               = try(local.config.features.networking.dhcp_options.enabled, false)
    dhcp_options_domain_name          = try(local.config.features.networking.dhcp_options.domain_name, null)
    dhcp_options_domain_name_servers  = try(local.config.features.networking.dhcp_options.domain_name_servers, null)
    dhcp_options_ntp_servers          = try(local.config.features.networking.dhcp_options.ntp_servers, null)
    dhcp_options_netbios_name_servers = try(local.config.features.networking.dhcp_options.netbios_name_servers, null)
    dhcp_options_netbios_node_type    = try(local.config.features.networking.dhcp_options.netbios_node_type, null)
    availability_zones                = local.config.features.networking.availability_zones
    egress_subnets                    = local.config.features.networking.egress_subnets
    enable_flow_logs                  = local.config.features.networking.flow_logs.enabled
    flow_log_retention_days           = try(local.config.features.networking.flow_log_retention_days, 7)
  }
}
