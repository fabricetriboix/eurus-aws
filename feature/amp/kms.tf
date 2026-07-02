module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt Amazon Managed Prometheus data"
  region                  = var.region
  aliases                 = ["amp"]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  key_statements = [
    {
      sid = "Root"
      actions = ["kms:*"]
      principals = [
        {
          type = "AWS"
          identifiers = ["arn:aws:iam::${local.account_id}:root"]
        }
      ]
      resources = ["*"]
    },
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${var.region}.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${var.region}:${local.account_id}:log-group:/amp/*",
          ]
        }
      ]
    },
    {
      sid = "AmazonManagedPrometheus"
      actions = [
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:GenerateDataKey",
        "kms:Decrypt",
      ]
      resources = ["*"]

      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["aps.${var.region}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [local.account_id]
        },
      ]
    },
  ]

  tags = merge(local.tags, {
    Name    = "alias/amp",
    Purpose = "Encrypt Amazon Managed Prometheus data"
  })
}
