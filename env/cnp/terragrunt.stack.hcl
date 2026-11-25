include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

locals {
  config      = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
  region_cfgs = local.config.features.networking.region_cfgs
}

unit "networking" {
  expansion {
    count = length(local.global.locals.regions)
  }
  enabled = !contains(local.config.skip_regions, count.index)

  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.networking.version)) ? "" : "feature/networking"}?ref=${local.config.features.networking.version}"

  path = "feature-networking-${count.index}"

  values = {
    enabled                           = local.config.features.networking.enabled
    version                           = local.config.features.networking.version
    account_type                      = local.config.account_type
    realm                             = local.config.realm
    env                               = local.config.env
    region                            = include.global.locals.regions[count.index]
    cidr                              = local.region_cfgs[count.index].cidr
    secondary_cidrs                   = try(local.region_cfgs[count.index].secondary_cidrs, null)
    enable_dhcp_options               = try(local.region_cfgs[count.index].enable_dhcp_options, false)
    dhcp_options_domain_name          = try(local.region_cfgs[count.index].dhcp_options_domain_name, null)
    dhcp_options_domain_name_servers  = try(local.region_cfgs[count.index].dhcp_options_domain_name_servers, null)
    dhcp_options_ntp_servers          = try(local.region_cfgs[count.index].dhcp_options_ntp_servers, null)
    dhcp_options_netbios_name_servers = try(local.region_cfgs[count.index].dhcp_options_netbios_name_servers, null)
    dhcp_options_netbios_node_type    = try(local.region_cfgs[count.index].dhcp_options_netbios_node_type, null)
    availability_zones                = local.region_cfgs[count.index].availability_zones
    egress_subnets                    = try(local.region_cfgs[count.index].egress_subnets, null)
    platform_subnets                  = local.region_cfgs[count.index].platform_subnets
    enable_flow_logs                  = try(local.config.features.networking.enable_flow_logs, true)
    flow_logs_retention_days          = try(local.config.features.networking.flow_logs_retention_days, 7)
  }
}

#unit "networking_region1" {
#  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
#  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
#  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.networking.version)) ? "" : "feature/networking"}?ref=${local.config.features.networking.version}"
#
#  path = "feature-networking1"
#
#  values = {
#    enabled                           = local.config.features.networking.enabled
#    version                           = local.config.features.networking.version
#    account_type                      = local.config.account_type
#    realm                             = local.config.realm
#    env                               = local.config.env
#    region                            = include.global.locals.regions[0]
#    cidr                              = local.region_cfgs[0].cidr
#    secondary_cidrs                   = try(local.region_cfgs[0].secondary_cidrs, null)
#    enable_dhcp_options               = try(local.region_cfgs[0].enable_dhcp_options, false)
#    dhcp_options_domain_name          = try(local.region_cfgs[0].dhcp_options_domain_name, null)
#    dhcp_options_domain_name_servers  = try(local.region_cfgs[0].dhcp_options_domain_name_servers, null)
#    dhcp_options_ntp_servers          = try(local.region_cfgs[0].dhcp_options_ntp_servers, null)
#    dhcp_options_netbios_name_servers = try(local.region_cfgs[0].dhcp_options_netbios_name_servers, null)
#    dhcp_options_netbios_node_type    = try(local.region_cfgs[0].dhcp_options_netbios_node_type, null)
#    availability_zones                = local.region_cfgs[0].availability_zones
#    egress_subnets                    = try(local.region_cfgs[0].egress_subnets, null)
#    platform_subnets                  = try(local.region_cfgs[0].platform_subnets, null)
#    enable_flow_logs                  = try(local.config.features.networking.enable_flow_logs, true)
#    flow_logs_retention_days          = try(local.config.features.networking.flow_logs_retention_days, 7)
#  }
#}
#
#unit "networking_region2" {
#  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
#  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
#  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.networking.version)) ? "" : "feature/networking"}?ref=${local.config.features.networking.version}"
#
#  path = "feature-networking2"
#
#  values = {
#    enabled                           = local.config.features.networking.enabled
#    version                           = local.config.features.networking.version
#    account_type                      = local.config.account_type
#    realm                             = local.config.realm
#    env                               = local.config.env
#    region                            = include.global.locals.regions[1]
#    cidr                              = local.region_cfgs[1].cidr
#    secondary_cidrs                   = try(local.region_cfgs[1].secondary_cidrs, null)
#    enable_dhcp_options               = try(local.region_cfgs[1].enable_dhcp_options, false)
#    dhcp_options_domain_name          = try(local.region_cfgs[1].dhcp_options_domain_name, null)
#    dhcp_options_domain_name_servers  = try(local.region_cfgs[1].dhcp_options_domain_name_servers, null)
#    dhcp_options_ntp_servers          = try(local.region_cfgs[1].dhcp_options_ntp_servers, null)
#    dhcp_options_netbios_name_servers = try(local.region_cfgs[1].dhcp_options_netbios_name_servers, null)
#    dhcp_options_netbios_node_type    = try(local.region_cfgs[1].dhcp_options_netbios_node_type, null)
#    availability_zones                = local.region_cfgs[1].availability_zones
#    egress_subnets                    = try(local.region_cfgs[1].egress_subnets, null)
#    platform_subnets                  = try(local.region_cfgs[1].platform_subnets, null)
#    enable_flow_logs                  = try(local.config.features.networking.enable_flow_logs, true)
#    flow_logs_retention_days          = try(local.config.features.networking.flow_logs_retention_days, 7)
#  }
#}

#unit "amg" {
#  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
#  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
#  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.amg.version)) ? "" : "feature/amg"}?ref=${local.config.features.amg.version}"
#
#  path = "feature-amg"
#
#  values = {
#    enabled                 = local.config.features.amg.enabled
#    version                 = local.config.features.amg.version
#    account_type            = local.config.account_type
#    realm                   = local.config.realm
#    env                     = local.config.env
#    logs_retention_days     = try(local.config.features.amg.logs_retention_days, 10)
#    data_source_account_ids = compact([
#      for id in split(",", get_env("APP_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
#    ])
#  }
#}
#
#unit "codeartifact" {
#  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
#  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
#  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.codeartifact.version)) ? "" : "feature/codeartifact"}?ref=${local.config.features.codeartifact.version}"
#
#  path = "feature-codeartifact"
#
#  values = {
#    enabled                     = local.config.features.codeartifact.enabled
#    version                     = local.config.features.codeartifact.version
#    account_type                = local.config.account_type
#    realm                       = local.config.realm
#    env                         = local.config.env
#    public_repositories         = try(local.config.features.codeartifact.public_repositories, [])
#    internal_formats            = try(local.config.features.codeartifact.internal_formats, [])
#    internal_packages_namespace = try(local.config.features.codeartifact.internal_packages_namespace, null)
#    internal_maven_namespace    = try(local.config.features.codeartifact.internal_maven_namespace, null)
#  }
#}
#
#unit "ecr" {
#  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
#  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
#  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.ecr.version)) ? "" : "feature/ecr"}?ref=${local.config.features.ecr.version}"
#
#  path = "feature-ecr"
#
#  values = {
#    enabled                 = local.config.features.ecr.enabled
#    version                 = local.config.features.ecr.version
#    account_type            = local.config.account_type
#    realm                   = local.config.realm
#    env                     = local.config.env
#    retention_in_days       = try(local.config.features.ecr.retention_in_days, 90)
#  }
#}
