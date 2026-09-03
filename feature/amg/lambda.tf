# Lambda function to manage data sources

data "aws_iam_policy_document" "datasrc_exec_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "datasrc_exec_role" {
  name               = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc-exec-role"
  assume_role_policy = data.aws_iam_policy_document.datasrc_exec_role_trust_policy.json

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc-exec-role"
    Purpose = "Allow the datasrc Lambda function to access the necessary AWS resources"
  }
}

data "aws_iam_policy_document" "datasrc_exec_role_policy" {
  statement {
    sid = "AllowAccessToAmgWorkspace"

    actions = [
      "grafana:CreateWorkspaceServiceAccountToken",
      "grafana:DeleteWorkspaceServiceAccountToken",
      "grafana:DescribeWorkspace"
    ]

    resources = [aws_grafana_workspace.this.arn]
  }

  statement {
    sid = "AllowAccessToCloudwatchLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.datasrc.arn,
      "${aws_cloudwatch_log_group.datasrc.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "datasrc_exec_role_policy" {
  name   = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc-exec-role-policy"
  policy = data.aws_iam_policy_document.datasrc_exec_role_policy.json

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc-exec-role-policy"
    Purpose = "Allow the datasrc Lambda function to access the necessary AWS resources"
  }
}

resource "aws_iam_role_policy_attachment" "datasrc_exec_role_policy_attachment" {
  role       = aws_iam_role.datasrc_exec_role.name
  policy_arn = aws_iam_policy.datasrc_exec_role_policy.arn
}

data "archive_file" "datasrc" {
  type        = "zip"
  output_path = "${path.module}/datasrc.zip"
  source_dir  = "${path.module}/datasrc"
  excludes    = ["__pycache__"]
}

resource "aws_cloudwatch_log_group" "datasrc" {
  name       = "/${var.org}/${var.project}/${var.env}/amg/datasrc"
  kms_key_id = module.key.key_arn

  # checkov:skip=CKV_AWS_338:Retention of less than one year is allowed
  retention_in_days = var.logs_retention_days

  tags = {
    Name    = "/${var.org}/${var.project}/${var.env}/amg/datasrc"
    Purpose = "Log group for the datasrc Lambda function"
  }
}

resource "aws_lambda_function" "datasrc" {
  # checkov:skip=CKV_AWS_272:Signing not necessary here
  # checkov:skip=CKV_AWS_173:Environment variables are not sensitive
  # checkov:skip=CKV_AWS_50:X-Ray tracing is not required for this function
  # checkov:skip=CKV_AWS_115:Reserved concurrency is not required for this function
  # checkov:skip=CKV_AWS_116:DLQ is not required for this synchronously invoked function
  # checkov:skip=CKV_AWS_117:This function does not need VPC access

  function_name    = "${var.org}-${var.project}-${var.env}-amg-datasrc"
  description      = "Lambda function to manage data sources in Amazon Managed Grafana"
  role             = aws_iam_role.datasrc_exec_role.arn
  handler          = "datasrc.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.datasrc.output_path
  source_code_hash = data.archive_file.datasrc.output_base64sha256
  memory_size      = 256
  region           = var.region
  timeout          = 30
  publish          = true

  environment {
    variables = {
      AMG_WORKSPACE_ID       = aws_grafana_workspace.this.id
      AMG_SERVICE_ACCOUNT_ID = aws_grafana_workspace_service_account.sa.service_account_id
    }
  }

  logging_config {
    application_log_level = "INFO"
    system_log_level      = "INFO"
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.datasrc.name
  }

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-amg-datasrc"
    Purpose = "Lambda function to manage data sources in Amazon Managed Grafana"
  }
}

resource "aws_lambda_alias" "datasrc" {
  name             = "live"
  description      = "Alias used by app accounts to register Grafana data sources"
  function_name    = aws_lambda_function.datasrc.function_name
  function_version = aws_lambda_function.datasrc.version
  region           = var.region
}

resource "aws_lambda_permission" "datasrc" {
  for_each = toset(var.data_source_account_ids)

  statement_id  = "AllowExecutionFrom-${each.value}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.datasrc.function_name
  qualifier     = aws_lambda_alias.datasrc.name
  principal     = each.value
  region        = var.region
}
