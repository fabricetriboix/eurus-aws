locals {
  bucket_name = "${var.org}-${var.project}-${var.account_type}-${var.realm}-${var.region}-ecr"
}

module "ecr_bucket" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:Ignore false positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.15.4-1"

  bucket              = local.bucket_name
  region              = var.region
  allowed_kms_key_arn = module.key.key_arn
  force_destroy       = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm            = "aws:kms"
        kms_master_key_id        = "alias/${local.kms_alias}"
        bucket_key_enabled       = true
        blocked_encryption_types = ["SSE-C"]
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  tags = {
    Name    = local.bucket_name
    Purpose = "Store ECR-related artifacts"
  }
}
