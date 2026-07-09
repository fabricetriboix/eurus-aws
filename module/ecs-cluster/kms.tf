module "key" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt ECS volumes"
  region                  = var.region
  aliases                 = [local.kms_alias]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  key_statements = [
    {
      sid = "Root"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${local.account_id}:root"]
        }
      ]
      actions   = ["kms:*"]
      resources = ["*"]
    },
    {
      sid = "Allow generate data key for Fargate tasks"
      principals = [
        {
          type        = "Service"
          identifiers = ["fargate.amazonaws.com"]
        }
      ]
      actions = ["kms:GenerateDataKeyWithoutPlaintext"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
          values   = [local.account_id]
        },
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:aws:ecs:clusterName"
          values   = [local.cluster_name]
        }
      ]
      resources = ["*"]
    },
    {
      sid = "Allow grant creation permission for Fargate tasks"
      principals = [
        {
          type        = "Service"
          identifiers = ["fargate.amazonaws.com"]
        }
      ]
      actions = ["kms:CreateGrant"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
          values   = [local.account_id]
        },
        {
          test     = "StringEquals"
          variable = "kms:EncryptionContext:aws:ecs:clusterName"
          values   = [local.cluster_name]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "kms:GrantOperations"
          values   = ["Decrypt"]
        }
      ]
      resources = ["*"]
    }
  ]

  tags = merge(local.tags, {
    Name    = "alias/${local.kms_alias}",
    Purpose = "Encrypt ECS volumes"
  })
}
