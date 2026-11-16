locals {
  config = yamldecode(file("${get_terragrunt_dir()}/config.yaml"))
}

unit "networking" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  # Version tags (feature-FEATURENAME-vX.Y.Z) use git subtrees (no path); branches need the feature path.
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//${can(regex("^feature-.+-v[0-9]+\\.[0-9]+\\.[0-9]+$", local.config.features.networking.version)) ? "" : "feature/networking"}?ref=${local.config.features.networking.version}"

  path = "feature-networking"

  values = {
    enabled       = local.config.features.networking.enabled
    version       = local.config.features.networking.version
    account_type  = local.config.account_type
    realm         = local.config.realm
    env           = local.config.env
    region_cfgs   = local.config.features.networking.region_cfgs
    flow_logs_cfg = local.config.features.networking.flow_logs_cfg
  }
}

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
