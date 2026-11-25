locals {
  tf_bucket_name   = "${var.org}-${var.project}-${var.account_type}-${var.realm}-${var.account_name}-${var.region}-tf"
  logs_bucket_name = "${local.tf_bucket_name}-logs"
}

module "logs_bucket" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:Ignore false positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.15.4-1"

  bucket              = local.logs_bucket_name
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

  # Don't keep logs forever
  lifecycle_rule = [
    {
      id     = "cleanup"
      status = "Enabled"

      expiration = {
        days = 90
      }
    }
  ]

  access_log_delivery_policy_source_buckets = [module.tf_bucket.s3_bucket_arn]
  attach_access_log_delivery_policy         = true

  tags = merge(local.tags, {
    Name    = local.logs_bucket_name
    Purpose = "Store access logs from the OpenTofu states bucket for the ${var.realm} realm"
  })
}

module "tf_bucket" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:Ignore false positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.15.4-1"

  bucket              = local.tf_bucket_name
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

  # Remove versions of the state files older than 90 days
  lifecycle_rule = [
    {
      id     = "cleanup"
      status = "Enabled"

      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
    }
  ]

  logging = {
    target_bucket = module.logs_bucket.s3_bucket_id
    target_prefix = "tf-logs/"

    target_object_key_format = {
      partitioned_prefix = {
        partitioned_data_source = "EventTime"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  tags = merge(local.tags, {
    Name    = local.tf_bucket_name
    Purpose = "Store OpenTofu states for the ${var.realm} realm"
  })
}
