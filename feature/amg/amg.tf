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
  name               = "${var.org}-${var.project}-${var.env}-${var.region}-amg"
  assume_role_policy = data.aws_iam_policy_document.amg_assume_role_policy.json

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-${var.region}-amg"
    Purpose = "Allow Amazon Managed Grafana to access what it needs to access"
  }
}

data "aws_iam_policy_document" "amg_policy" {
  statement {
    sid     = "AllowAssumeRole"
    actions = ["sts:AssumeRole"]

    resources = [
      for id in var.data_source_account_ids : "arn:aws:iam::${id}:role/${var.org}-${var.project}-*-${var.region}-amp-datasrc"
    ]
  }
}

resource "aws_iam_policy" "amg_policy" {
  name   = "${var.org}-${var.project}-${var.env}-${var.region}-amg-policy"
  policy = data.aws_iam_policy_document.amg_policy.json
}

resource "aws_iam_role_policy_attachment" "amg_policy_attachment" {
  role       = aws_iam_role.amg.name
  policy_arn = aws_iam_policy.amg_policy.arn
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
  grafana_version          = "12.4"

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

