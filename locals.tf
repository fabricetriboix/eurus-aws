locals {
  default_tags = {
    FeatureSource  = "feature/ecs-plf"
    FeatureVersion = var.feature_version
    Organization   = var.org
    Project        = var.project
    Region         = var.region
    Environment    = var.env
    ManagedBy      = "OpenTofu"
  }
}
