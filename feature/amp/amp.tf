# Amazon Managed Prometheus

resource "aws_cloudwatch_log_group" "this" {
  name       = "/${var.org}/${var.project}/${var.env}/amp-logs"
  region     = var.region
  kms_key_id = module.key.key_arn

  # checkov:skip=CKV_AWS_338:Retention of less than one year is allowed
  retention_in_days = var.logs_retention_days

  tags = {
    Name    = "/${var.org}/${var.project}/${var.env}/amp-logs"
    Purpose = "Amazon Managed Prometheus log group for ${var.org}-${var.project}-${var.env}"
  }
}

resource "aws_prometheus_workspace" "this" {
  alias       = "${var.org}-${var.project}-${var.env}"
  region      = var.region
  kms_key_arn = module.key.key_arn

  logging_configuration {
    log_group_arn = "${aws_cloudwatch_log_group.this.arn}:*"
  }

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}"
    Purpose = "Amazon Managed Prometheus workspace for ${var.org}-${var.project}-${var.env}"
  }
}

data "aws_iam_policy_document" "amp_policy" {
  statement {
    sid = "AllowAccessFromAmp"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.common_account_id}:root"]
    }

    actions = [
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricsMetadata"
    ]

    resources = [aws_prometheus_workspace.this.arn]
  }
}

resource "aws_prometheus_resource_policy" "amp_policy" {
  workspace_id    = aws_prometheus_workspace.this.id
  policy_document = data.aws_iam_policy_document.amp_policy.json
}
