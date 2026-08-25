module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt container images stored in ECR"
  region                  = var.region
  aliases                 = ["ecr"]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  tags = {
    Name    = "alias/ecr",
    Purpose = "Encrypt container images stored in ECR"
  }
}
