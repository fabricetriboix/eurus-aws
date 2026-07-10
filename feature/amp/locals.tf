data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  tags = {
    FeatureSource  = "feature/amp"
    FeatureVersion = var.version
  }
}
