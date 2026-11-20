module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.2.1-1"

  description             = "Key to encrypt PKI-related artifacts and metadata"
  region                  = var.region
  aliases                 = [local.kms_alias]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  key_statements = [
    {
      sid = "AllowGrantsForPkiTemplateRole"

      principals = [
        {
          type        = "AWS"
          identifiers = [aws_iam_role.role_for_template.arn]
        }
      ]

      actions = [
        "kms:CreateGrant",
        "kms:RetireGrant"
      ]

      resources = ["*"]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["ecr.${var.region}.amazonaws.com"]
        },
        {
          test     = "Bool"
          variable = "kms:GrantIsForAWSResource"
          values   = ["true"]
        },
      ]
    },
    {
      sid = "AllowDescribeKeyForEcrTemplateRole"

      principals = [
        {
          type        = "AWS"
          identifiers = [aws_iam_role.role_for_template.arn]
        }
      ]

      actions = [
        "kms:DescribeKey"
      ]

      resources = ["*"]
    }
  ]

  tags = {
    Name    = "alias/${local.kms_alias}",
    Purpose = "Key to encrypt PKI-related artifacts and metadata"
  }
}
