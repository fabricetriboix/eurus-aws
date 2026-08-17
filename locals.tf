data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  domain_name = "${var.org}-${var.project}-${var.realm}"

  default_tags = {
    FeatureSource  = "feature/codeartifact"
    FeatureVersion = var.feature_version
    Organization   = var.org
    Project        = var.project
    Environment    = var.env
    ManagedBy      = "OpenTofu"
  }
}
