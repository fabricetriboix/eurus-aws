module "key" {
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt OpenTofu states and DynamoDB lock tables"
  aliases                 = ["tf"]
  deletion_window_in_days = 7
  rotation_period_in_days = 30

  tags = merge(local.tags, {
    Name = "alias/tf"
  })
}
