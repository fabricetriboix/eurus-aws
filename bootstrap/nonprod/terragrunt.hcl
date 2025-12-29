locals {
  ts = timestamp()
}

generate "tags" {
  path      = "tg_generated_tags.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
locals {
  default_tags = {
    UpdatedAt = "${ local.ts }"
  }
}
EOF
}
