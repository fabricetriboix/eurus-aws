generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
    terraform {
      backend "s3" {
        bucket         = "eurus-aws-tf-states"
        key            = "${path_relative_to_include()}/tofu.tfstate"
        region         = "eu-central-1"
        encrypt        = true
        dynamodb_table = "eurus-aws-tofu-locks"
      }
    }
EOF
}
