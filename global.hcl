locals {
  region  = "eu-west-1"
  org     = "myorg"
  project = "myproject"

  tf_bucket_prefix = "${local.org}-${local.project}"

  # The name of the bucket that contains the OpenTofu state files is formed
  # like so: "{tf_bucket_prefix}-{account_type}-{realm}-tf"
  #
  # Examples:
  #   - "myorg-myproject-common-nonprod-tf"
  #   - "myorg-myproject-app-prod-tf"
}
