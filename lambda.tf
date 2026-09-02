# Lambda function to manage data sources

data "aws_iam_policy_document" "datasrc_exec_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "datasrc_exec_role" {
  name = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc-exec-role"
  assume_role_policy = data.aws_iam_policy_document.datasrc_exec_role_trust_policy.json

  tags = {
    Name = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc-exec-role"
    Purpose = "Allow the `datasrc` Lambda function to access the necessary AWS resources"
  }
}

data "archive_file" "datasrc" {
  type = "zip"
  output_path = "datasrc.zip"
  source_dir = "${path.module}/datasrc"
}

resource "aws_cloudwatch_log_group" "datasrc" {
  name       = "/${var.org}/${var.project}/${var.env}/amg/datasrc"
  kms_key_id = module.key[0].key_arn

  # checkov:skip=CKV_AWS_338:Retention of less than one year is allowed
  retention_in_days = var.logs_retention_days

  tags = {
    Name = "/${var.org}/${var.project}/${var.env}/amg/datasrc"
  }
}

resource "aws_lambda_function" "datasrc" {
  function_name = "${var.org}-${var.project}-${var.env}-datasrc"
  description = "Lambda function to manage data sources in Amazon Managed Grafana"
  role = aws_iam_role.datasrc_exec_role.arn
  handler = "datasrc.lambda_handler"
  runtime = "python3.12"
  filename = data.archive_file.datasrc.output_path
  source_code_hash = data.archive_file.datasrc.output_base64sha256
  memory_size = 256
  region = var.region
  timeout = 30

  environment {
    variables = {
      AMG_WORKSPACE_ID = local.workspace_id
      AMG_SERVICE_ACCOUNT_ID = amazon_grafana_workspace_service_account.sa.id
    }
  }

  logging_config {
    level = "INFO"
    system_log_level = "INFO"
    log_format = "JSON"
    log_group = aws_cloudwatch_log_group.datasrc.name
  }

  tags = {
    Name = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc"
    Purpose = "Lambda function to manage data sources in Amazon Managed Grafana"
  }
}