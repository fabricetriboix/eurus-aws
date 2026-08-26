data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  source_account_ids = toset(concat([local.account_id], var.source_account_ids))
  pull_account_ids   = toset(concat([local.account_id], var.pull_account_ids))

  default_tags = {
    FeatureSource  = "feature/ecr"
    FeatureVersion = var.feature_version
    Organization   = var.org
    Project        = var.project
    Environment    = var.env
    ManagedBy      = "OpenTofu"
  }
}
