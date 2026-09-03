# Register ourselves as a data source in Amazon Managed Grafana

data "aws_iam_policy_document" "amp_datasrc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.common_account_id}:role/${var.org}-${var.project}-${var.common_account_env}-${var.region}-amg"]
    }
  }
}

resource "aws_iam_role" "amp_datasrc" {
  name               = "${var.org}-${var.project}-${var.env}-${var.region}-amp-datasrc"
  assume_role_policy = data.aws_iam_policy_document.amp_datasrc_assume_role_policy.json

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-${var.region}-amp-datasrc"
    Purpose = "Role assumed by Amazon Managed Grafana to query this AMP workspace"
  }
}

data "aws_iam_policy_document" "amp_datasrc_policy" {
  statement {
    sid = "AllowAccessToAmpWorkspace"

    actions = [
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricMetadata"
    ]

    resources = [aws_prometheus_workspace.this.arn]
  }
}

resource "aws_iam_policy" "amp_datasrc_policy" {
  name   = "${var.org}-${var.project}-${var.env}-${var.region}-amp-datasrc-policy"
  policy = data.aws_iam_policy_document.amp_datasrc_policy.json

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-${var.region}-amp-datasrc-policy"
    Purpose = "Allow Amazon Managed Grafana to query this AMP workspace"
  }
}

resource "aws_iam_role_policy_attachment" "amp_datasrc_policy_attachment" {
  role       = aws_iam_role.amp_datasrc.name
  policy_arn = aws_iam_policy.amp_datasrc_policy.arn
}

resource "aws_lambda_invocation" "amg_datasrc" {
  function_name   = "arn:aws:lambda:${var.region}:${var.common_account_id}:function:${var.org}-${var.project}-${var.common_account_env}-amg-datasrc:live"
  lifecycle_scope = "CRUD"

  input = jsonencode({
    name = "amp-${var.env}"
    type = "grafana-amazonprometheus-datasource"
    url  = aws_prometheus_workspace.this.prometheus_endpoint
    role = aws_iam_role.amp_datasrc.arn
  })
}
