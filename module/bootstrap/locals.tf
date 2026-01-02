data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  region       = data.aws_region.current.region
  kms_alias    = "alias/tf"
  account_type = var.is_common ? "common" : "app"

  tags = {
    ModuleSource = "modules/bootstrap"
  }
}
