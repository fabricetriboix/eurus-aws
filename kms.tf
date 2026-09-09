module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt Amazon Managed Grafana data"
  region                  = var.region
  aliases                 = ["amg"]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  key_statements = [
    {
      sid     = "Root"
      actions = ["kms:*"]
      principals = [
        {
          type        = "AWS"
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
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${var.region}.amazonaws.com"]
        }
      ]
      resources = ["*"]

      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${var.region}:${local.account_id}:log-group:/${var.org}/${var.project}/${var.env}/amg/*",
          ]
        }
      ]
    },
    {
      sid = "AllowOpenTofuAccessKey"
      actions = [
        "kms:DescribeKey",
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${local.account_id}:role/tf-role-${var.region}"]
        }
      ]
      resources = ["*"]
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["grafana.${var.region}.amazonaws.com"]
        }
      ]
    },
    {
      sid = "AllowOpenTofuCreateGrant"
      actions = [
        "kms:CreateGrant"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${local.account_id}:role/tf-role-${var.region}"]
        }
      ]
      resources = ["*"]
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["grafana.${var.region}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:GrantConstraintType"
          values   = ["EncryptionContextSubset"]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "kms:GrantOperations"
          values = [
            "DescribeKey",
            "CreateGrant",
            "RetireGrant",
            "Decrypt",
            "Encrypt",
            "GenerateDataKey",
            "GenerateDataKeyWithoutPlaintext",
            "ReEncryptFrom",
            "ReEncryptTo"
          ]
        }
      ]
    }
  ]

  tags = {
    Name    = "alias/amg",
    Purpose = "Encrypt Amazon Managed Grafana data"
  }
}
