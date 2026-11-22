locals {
  default_tags = {
    FeatureSource  = "feature/networking"
    FeatureVersion = var.feature_version
    Organisation   = var.org
    Project        = var.project
    Region         = var.region
    Realm          = var.realm
    AccountType    = var.account_type
    Environment    = var.env
    Tenant         = "plf"
    ManagedBy      = "OpenTofu"
  }
}
