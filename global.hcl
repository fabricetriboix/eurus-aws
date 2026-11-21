locals {
  regions = [get_env("AWS_REGION1"), get_env("AWS_REGION2")]
  org     = get_env("ORG")
  project = get_env("PROJECT")

  tf_bucket_prefix = "${local.org}-${local.project}"

  # The name of the buckets that contains the OpenTofu state files is formed
  # like so: "{tf_bucket_prefix}-{account_type}-{realm}-{regions[*]}-tf"
  #
  # There will be one such bucket per region.
  #
  # Examples:
  #   - "ft-eurus-common-nonprod-eu-west-1-tf"
  #   - "ft-eurus-dev-prod-eu-west-2-tf
}
