locals {
  config = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

unit "networking" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//?ref=${local.config.features.networking.version}"
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git//feature/networking?ref=fix-version-tag"

  path = "feature-networking"

  values = {
    enabled                           = local.config.features.networking.enabled
    version                           = local.config.features.networking.version
    account_type                      = local.config.account_type
    realm                             = local.config.realm
    env                               = local.config.env
    cidr                              = local.config.features.networking.cidr
    secondary_cidrs                   = try(local.config.features.networking.secondary_cidrs, null)
    enable_dhcp_options               = try(local.config.features.networking.dhcp_options.enabled, false)
    dhcp_options_domain_name          = try(local.config.features.networking.dhcp_options.domain_name, null)
    dhcp_options_domain_name_servers  = try(local.config.features.networking.dhcp_options.domain_name_servers, null)
    dhcp_options_ntp_servers          = try(local.config.features.networking.dhcp_options.ntp_servers, null)
    dhcp_options_netbios_name_servers = try(local.config.features.networking.dhcp_options.netbios_name_servers, null)
    dhcp_options_netbios_node_type    = try(local.config.features.networking.dhcp_options.netbios_node_type, null)
    availability_zones                = local.config.features.networking.availability_zones
    egress_subnets                    = try(local.config.features.networking.egress_subnets, null)
    platform_subnets                  = local.config.features.networking.platform_subnets
    enable_flow_logs                  = local.config.features.networking.flow_logs.enabled
    flow_logs_retention_days          = try(local.config.features.networking.flow_logs_retention_days, 7)
  }
}

unit "ecs-plf" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.ecs-plf.version)) ? "" : "feature/ecs-plf"}?ref=${local.config.features.ecs-plf.version}"

  path = "feature-ecs-plf"

  values = {
    enabled            = local.config.features.ecs-plf.enabled
    version            = local.config.features.ecs-plf.version
    account_type       = local.config.account_type
    realm              = local.config.realm
    env                = local.config.env
    log_retention_days = try(local.config.features.ecs-plf.log_retention_days, 7)
  }
}
