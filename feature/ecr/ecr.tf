# Enable blob mounting to share layers between repositories

resource "aws_ecr_account_setting" "blob_mounting" {
  region = var.region
  name  = "BLOB_MOUNTING"
  value = "ENABLED"
}

# Allow creation of repositories and pushing of images into this account

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid = "AllowCreateRepositoryAndPush"

    principals {
      type = "AWS"
      identifiers = [for id in local.source_account_ids : "arn:aws:iam::${id}:root"]
    }

    actions = [
      "ecr:CreateRepository",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = ["arn:aws:ecr:${var.region}:${local.account_id}:repository/*"]
  }
}

resource "aws_ecr_registry_policy" "ecr_policy" {
  region = var.region
  policy = data.aws_iam_policy_document.ecr_policy.json
}

# Repository template

data "aws_iam_policy_document" "assume_role_policy_for_template" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecr.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role_for_template" {
  name = "${var.org}-${var.project}-${var.env}-ecr-template"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_for_template.json
}

data "aws_iam_policy_document" "policy_for_template" {
  statement {
    sid = "AllowCreateRepository"

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions = [
      "ecr:CreateRepository",
      "ecr:TagResource"
    ]

    resources = ["arn:aws:ecr:${var.region}:${local.account_id}:repository/*"]
  }

  statement {
    sid = "AllowKmsKeyAccess"
    actions = [
      "kms:CreateGrant",
      "kms:RetireGrant",
      "kms:DescribeKey"
    ]

    resources = [module.key.key_arn]
  }
}

resource "aws_iam_policy" "policy_for_template" {
  name = "${var.org}-${var.project}-${var.env}-${var.region}-ecr-template"
  policy = data.aws_iam_policy_document.policy_for_template.json
}

resource "aws_iam_role_policy_attachment" "policy_for_template" {
  role = aws_iam_role.role_for_template.name
  policy_arn = aws_iam_policy.policy_for_template.arn
}

data "aws_ecr_lifecycle_policy_document" "retention" {
  rule {
    priority = 1
    description = "Expire images older than ${var.retention_in_days} days"

    selection {
      tag_status = "any"
      count_type = "sinceImagePushed"
      count_unit = "days"
      count_number = var.retention_in_days
    }

    action {
      type = "expire"
    }
  }
}

data "aws_iam_policy_document" "template_repository_policy" {
  statement {
    sid = "AllowGetAuthorizationToken"

    principals {
      type = "AWS"
      identifiers = [for id in local.pull_account_ids : "arn:aws:iam::${id}:root"]
    }

    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }

  statement {
    sid = "AllowCheckImage"

    principals {
      type = "AWS"
      identifiers = [for id in local.pull_account_ids : "arn:aws:iam::${id}:root"]
    }

    actions = [
      "ecr:DescribeImages",
      "ecr:DescribeRepositories"
    ]

    resources = ["arn:aws:ecr:${var.region}:${local.account_id}:repository/*"]
  }
}

resource "aws_ecr_repository_creation_template" "this" {
  region = var.region
  prefix = "ROOT"
  applied_for = ["CREATE_ON_PUSH", "PULL_THROUGH_CACHE", "REPLICATION"]
  custom_role_arn = aws_iam_role.role_for_template.arn
  image_mutability = "IMMUTABLE"
  lifecycle_policy = var.retention_in_days > 0 ? data.aws_ecr_lifecycle_policy_document.retention.json : null
  repository_policy = data.aws_iam_policy_document.template_repository_policy.json

  resource_tags = merge(local.default_tags, {
    RepositoryConfigurationFrom = "ecr_repository_creation_template"
  })

  encryption_configuration {
    encryption_type = "KMS"
    kms_key = module.key.key_arn
  }
}
