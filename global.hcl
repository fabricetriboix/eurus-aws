locals {
  region  = "eu-west-1"
  org     = "myorg"
  project = "myproject"

  # The name of the bucket that contains the OpenTofu state files is formed
  # like so: "{tf_bucket_prefix}-{account_type}-{realm}"
  #
  # Examples:
  #   - "myorg-myproject-tf-common-nonprod"
  #   - "myorg-myproject-tf-app-prod"
  tf_bucket_prefix = "${local.org}-${local.project}-tf-"
}
