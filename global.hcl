locals {
  region  = "eu-west-1"
  org     = "ft"
  project = "eurus"

  tf_bucket_prefix = "${local.org}-${local.project}-tf-"

  # The name of the bucket that contains the OpenTofu state files is formed
  # like so: "{tf_bucket_prefix}-{account_type}-{realm}"
  #
  # Examples:
  #   - "ft-eurus-tf-common-nonprod"
  #   - "ft-eurus-tf-app-prod"
}
