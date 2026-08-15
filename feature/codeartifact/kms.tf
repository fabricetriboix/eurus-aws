module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt CodeArtifact data"
  region                  = var.region
  aliases                 = ["codeartifact"]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  tags = {
    Name    = "alias/codeartifact",
    Purpose = "Encrypt CodeArtifact data"
  }
}
