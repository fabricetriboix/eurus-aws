# Amazon Managed Grafana

data "aws_iam_policy_document" "grafana_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "grafana" {
  name               = "${var.org}-${var.project}-${var.env}-grafana"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role_policy.json

  tags = merge(local.tags, {
    Name    = "${var.org}-${var.project}-${var.env}-grafana"
    Purpose = "Allow Grafana to access what it needs to access"
  })
}

resource "aws_grafana_workspace" "this" {
  name                     = "${var.org}-${var.project}-${var.env}"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "CUSTOMER_MANAGED"
  region                   = var.region
  kms_key_id               = module.key.key_arn
  role_arn                 = aws_iam_role.grafana.arn

  tags = merge(local.tags, {
    Name    = "${var.org}-${var.project}-${var.env}"
    Purpose = "Grafana workspace for ${var.org}-${var.project}-${var.env}"
  })
}
