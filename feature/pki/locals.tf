locals {
  kms_alias = "pki"

  default_tags = {
    FeatureSource  = "feature/pki"
    FeatureVersion = var.feature_version
    Organization   = var.org
    Project        = var.project
    Region         = var.region
    Environment    = var.env
    ManagedBy      = "OpenTofu"
  }
}
