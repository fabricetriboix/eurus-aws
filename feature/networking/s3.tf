module "key" {
  count = var.enable_flow_logs ? 1 : 0

  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.2.1-1"

  description             = "Key to encrypt VPC flow logs"
  region                  = var.region
  aliases                 = [local.kms_alias]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  key_statements = [
    {
      sid = "AllowVpcFlowLogsDeliveryToS3"

      principals = [
        {
          type        = "Service"
          identifiers = ["delivery.logs.amazonaws.com"]
        }
      ]

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]

      resources = ["*"]

      condition = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [local.account_id]
        },
        {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = ["arn:aws:logs:${var.region}:${local.account_id}:*"]
        }
      ]
    }
  ]

  tags = {
    Name    = "alias/${local.kms_alias}"
    Purpose = "Encrypt VPC flow logs"
  }
}

data "aws_iam_policy_document" "vpc_flow_logs_bucket" {
  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${var.region}:${local.account_id}:*"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::${local.bucket_name}"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${var.region}:${local.account_id}:*"]
    }
  }
}

module "vpc_flow_logs_bucket" {
  count = var.enable_flow_logs ? 1 : 0

  # checkov:skip=CKV_TF_1,CKV_TF_2:Ignore false positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-s3-bucket.git?ref=v5.15.4-1"

  bucket              = local.bucket_name
  region              = var.region
  allowed_kms_key_arn = module.key[0].key_arn
  force_destroy       = true
  attach_policy       = true
  policy              = data.aws_iam_policy_document.vpc_flow_logs_bucket.json

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

  lifecycle_rule = {
    id      = "cleanup"
    prefix  = ""
    enabled = true
    expiration = {
      days = var.flow_logs_retention_days
    }
  }

  tags = {
    Name    = local.bucket_name
    Purpose = "Store VPC flow logs"
  }
}
