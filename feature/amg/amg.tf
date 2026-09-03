# Amazon Managed Grafana

data "aws_iam_policy_document" "amg_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "amg" {
  name               = "${var.org}-${var.project}-${var.env}-amg"
  assume_role_policy = data.aws_iam_policy_document.amg_assume_role_policy.json

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-amg"
    Purpose = "Allow Amazon Managed Grafana to access what it needs to access"
  }
}

data "aws_iam_policy_document" "amg_policy" {
  dynamic "statement" {
    for_each = toset(var.data_source_account_ids)

    statement {
      sid = "AllowAssumeRole-${statement.value}"

      actions = ["sts:AssumeRole"]

      resources = ["arn:aws:iam::${statement.value}:role/*"]
    }
  }
}

resource "aws_grafana_workspace" "this" {
  name                     = "${var.org}-${var.project}-${var.env}"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "CUSTOMER_MANAGED"
  region                   = var.region
  kms_key_id               = module.key.key_arn
  role_arn                 = aws_iam_role.amg.arn
  data_sources             = ["CLOUDWATCH", "PROMETHEUS"]

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}"
    Purpose = "Amazon Managed Grafana workspace for ${var.org}-${var.project}-${var.env}"
  }
}

resource "aws_grafana_workspace_service_account" "sa" {
  region       = var.region
  name         = "${var.org}-${var.project}-${var.env}-sa"
  grafana_role = "ADMIN"
  workspace_id = aws_grafana_workspace.this.id
}

