locals {
  tf_bucket_name   = "${var.org}-${var.project}-${var.realm}-tf-${var.region}"
  logs_bucket_name = "${bucket_name}-logs"
}

module "tf_bucket" {
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.9.1-1"

  bucket              = local.tf_bucket_name
  allowed_kms_key_arn = module.key.arn

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm            = "aws:kms"
        kms_master_key_id        = module.key.aliases[0].name
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
    target_bucket = aws_s3_bucket.logs_bucket.name
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

module "logs_bucket" {
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.9.1-1"

  bucket              = local.logs_bucket_name
  allowed_kms_key_arn = module.key.arn

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm            = "aws:kms"
        kms_master_key_id        = module.key.aliases[0].name
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

  access_log_delivery_policy_source_buckets = module.tf_bucket.arn
  attach_access_log_delivery_policy         = true

  tags = merge(local.tags, {
    Name    = local.logs_bucket_name
    Purpose = "Store access logs from the OpenTofu states bucket for the ${var.realm} realm"
  })
}
