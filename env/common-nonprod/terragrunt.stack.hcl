locals {
  config = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

unit "networking" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.networking.version)) ? "" : "feature/networking"}?ref=${local.config.features.networking.version}"

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

unit "amg" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.amg.version)) ? "" : "feature/amg"}?ref=${local.config.features.amg.version}"

  path = "feature-amg"

  values = {
    enabled                 = local.config.features.amg.enabled
    version                 = local.config.features.amg.version
    account_type            = local.config.account_type
    realm                   = local.config.realm
    env                     = local.config.env
    data_source_account_ids = compact([
      for id in split(",", get_env("APP_NONPROD_ACCOUNT_IDS", "")) : trimspace(id)
    ])
  }
}

unit "codeartifact" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.codeartifact.version)) ? "" : "feature/codeartifact"}?ref=${local.config.features.codeartifact.version}"

  path = "feature-codeartifact"

  values = {
    enabled                     = local.config.features.codeartifact.enabled
    version                     = local.config.features.codeartifact.version
    account_type                = local.config.account_type
    realm                       = local.config.realm
    env                         = local.config.env
    public_repositories         = try(local.config.features.codeartifact.public_repositories, [])
    internal_formats            = try(local.config.features.codeartifact.internal_formats, [])
    internal_packages_namespace = try(local.config.features.codeartifact.internal_packages_namespace, null)
    internal_maven_namespace    = try(local.config.features.codeartifact.internal_maven_namespace, null)
  }
}

unit "ecr" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.ecr.version)) ? "" : "feature/ecr"}?ref=${local.config.features.ecr.version}"

  path = "feature-ecr"

  values = {
    enabled                 = local.config.features.ecr.enabled
    version                 = local.config.features.ecr.version
    account_type            = local.config.account_type
    realm                   = local.config.realm
    env                     = local.config.env
    retention_in_days       = try(local.config.features.ecr.retention_in_days, 90)
  }
}
