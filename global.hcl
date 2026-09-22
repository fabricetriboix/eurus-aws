locals {
  region  = get_env("AWS_REGION")
  org     = get_env("ORG")
  project = get_env("PROJECT")

  tf_bucket_prefix = "${local.org}-${local.project}"

  # The name of the bucket that contains the OpenTofu state files is formed
  # like so: "{tf_bucket_prefix}-{account_type}-{realm}-{region}-tf"
  #
  # Examples:
  #   - "ft-eurus-common-nonprod-eu-west-1-tf"
  #   - "ft-eurus-dev-prod-eu-west-1-tf
}
