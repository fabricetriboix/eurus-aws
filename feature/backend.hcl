include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "s3" {
        bucket         = "${local.tf_bucket_prefix}-${local.account_type}-${local.realm}"
        key            = "${local.account_type}-${local.realm}/${path_relative_to_include()}/tofu.tfstate"
        region         = "${local.region}"
        encrypt        = true
        dynamodb_table = "eurus-aws-tofu-locks"
      }
    }
EOF
}
