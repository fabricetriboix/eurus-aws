locals {
  kms_alias = "vpc-flow-logs"

  tags = {
    FeatureSource = "feature/networking"
  }
}
