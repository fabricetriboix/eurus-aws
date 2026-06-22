# Amazon Managed Prometheus

resource "aws_cloudwatch_log_group" "this" {
  name              = "/amp/${var.org}-${var.project}-${var.env}"
  region            = var.region
  retention_in_days = var.log_retention_days
  kms_key_id        = module.key.key_arn

  tags = merge(local.tags, {
    Name    = "/amp/${var.org}-${var.project}-${var.env}"
    Purpose = "Amazon Managed Prometheus log group for ${var.org}-${var.project}-${var.env}"
  })
}

resource "aws_prometheus_workspace" "this" {
  alias       = "${var.org}-${var.project}-${var.env}"
  region      = var.region
  kms_key_arn = module.key.key_arn

  logging_configuration {
    log_group_arn = aws_cloudwatch_log_group.this.arn
  }

  tags = merge(local.tags, {
    Name    = "${var.org}-${var.project}-${var.env}"
    Purpose = "Amazon Managed Prometheus workspace for ${var.org}-${var.project}-${var.env}"
  })
}
