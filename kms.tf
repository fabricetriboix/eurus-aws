module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt CodeArtifact data"
  region                  = var.region
  aliases                 = ["codeartifact"]
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
      sid = "Allow access through AWS CodeArtifact for all principals in the account that are authorized to use CodeArtifact"
      actions = [
        "kms:CreateGrant",
        "kms:DescribeKey"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      resources = ["*"]

      condition = [
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [local.account_id]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["codeartifact.${var.region}.amazonaws.com"]
        }
      ]
    }
  ]

  tags = {
    Name    = "alias/codeartifact",
    Purpose = "Encrypt CodeArtifact data"
  }
}
