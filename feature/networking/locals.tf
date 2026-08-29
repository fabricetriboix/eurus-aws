locals {
  kms_alias = "vpc-flow-logs"

  default_tags = {
    FeatureSource  = "feature/ecr"
    FeatureVersion = var.feature_version
    Organization   = var.org
    Project        = var.project
    Region         = var.region
    Environment    = var.env
    ManagedBy      = "OpenTofu"
  }
}
