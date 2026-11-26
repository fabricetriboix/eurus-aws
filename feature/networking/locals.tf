data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.org}-${var.project}-${var.env}-${var.region}-vpc-flow-logs"
  kms_alias   = "vpc-flow-logs-${var.org}-${var.project}-${var.env}"
  account_id  = data.aws_caller_identity.current.account_id

  az_count = length(var.platform_subnets)
  azs      = [for i in range(local.az_count) : "${var.region}${substr("abcdefghijklmnopqrstuvwxyz", i, 1)}"]

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
