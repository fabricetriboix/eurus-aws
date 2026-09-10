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
            "arn:aws:logs:${var.region}:${local.account_id}:log-group:/${var.org}/${var.project}/${var.env}/ecs-cluster-logs/${local.cluster_name}",
          ]
        }
      ]
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
      condition = [
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
      condition = [
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
