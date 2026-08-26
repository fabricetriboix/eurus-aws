module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt container images stored in ECR"
  region                  = var.region
  aliases                 = ["ecr"]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  key_statements = [
    {
      sid = "AllowEcrTemplateRole"

      principals = [
        {
          type        = "AWS"
          identifiers = [aws_iam_role.role_for_template.arn]
        }
      ]

      actions = [
        "kms:DescribeKey",
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
    }
  ]

  tags = {
    Name    = "alias/ecr",
    Purpose = "Encrypt container images stored in ECR"
  }
}
