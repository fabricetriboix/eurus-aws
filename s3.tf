locals {
  tf_bucket_name   = "${var.org}-${var.project}-${local.type}-${var.realm}-tf-${local.region}"
  logs_bucket_name = "${local.tf_bucket_name}-logs"
}

module "logs_bucket" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.9.1-1"

  bucket              = local.logs_bucket_name
  allowed_kms_key_arn = module.key.key_arn

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm            = "aws:kms"
        kms_master_key_id        = "alias/tf"
        bucket_key_enabled       = true
        blocked_encryption_types = ["SSE-C"]
      }
    }
  }

  lifecycle_rule = [
    {
      id     = "cleanup"
      status = "Enabled"

      // Matches all objects in this bucket
      filter = {}

      expiration = {
        days = 365
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
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.9.1-1"

  bucket              = local.tf_bucket_name
  allowed_kms_key_arn = module.key.key_arn

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm            = "aws:kms"
        kms_master_key_id        = "alias/tf"
        bucket_key_enabled       = true
        blocked_encryption_types = ["SSE-C"]
      }
    }
  }

  lifecycle_rule = [
    {
      id     = "cleanup"
      status = "Enabled"

      // Matches all objects in this bucket
      filter = {}

      noncurrent_version_expiration = {
        noncurrent_days = 365
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
