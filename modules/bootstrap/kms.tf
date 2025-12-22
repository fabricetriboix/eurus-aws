module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:No tags yet in `terraform-aws-kms`
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=master"

  description              = "Key to encrypt OpenTofu states and DynamoDB lock tables"
  aliases                  = ["tf"]
  deletion_windows_in_days = 7
  rotation_period_in_days  = 30

  tags = {
    Name = "alias/tf"
  }
}
