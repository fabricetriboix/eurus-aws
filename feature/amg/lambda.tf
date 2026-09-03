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
    Purpose = "Allow the `datasrc` Lambda function to access the necessary AWS resources"
  }
}

local {
  datasrc_build_dir = "${path.module}/build-datasrc"
  datasrc_zip_path  = "${path.module}/datasrc.zip"
}

resource "terraform_data" "datasrc" {
  triggers_replace = [
    filebase64sha256("${path.module}/datasrc/datasrc.py"),
    filebase64sha256("${path.module}/datasrc/requirements.txt")
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]

    command = <<-END
      set -euo pipefail

      rm -rf "${local.datasrc_build_dir}"
      mkdir -p "${local.datasrc_build_dir}"

      python3 -m pip install -r "${path.module}/datasrc/requirements.txt" -t "${local.datasrc_build_dir}"

      cp "${path.module}/datasrc/datasrc.py" "${local.datasrc_build_dir}"
    END
  }
}

data "archive_file" "datasrc" {
  depends_on = [terraform_data.datasrc]

  type        = "zip"
  output_path = local.datasrc_zip_path
  source_dir  = local.datasrc_build_dir
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

  environment {
    variables = {
      AMG_WORKSPACE_ID       = local.workspace_id
      AMG_SERVICE_ACCOUNT_ID = amazon_grafana_workspace_service_account.sa.id
    }
  }

  logging_config {
    level            = "INFO"
    system_log_level = "INFO"
    log_format       = "JSON"
    log_group        = aws_cloudwatch_log_group.datasrc.name
  }

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-${var.region}-datasrc"
    Purpose = "Lambda function to manage data sources in Amazon Managed Grafana"
  }
}

resource "aws_lambda_permission" "datasrc" {
  for_each = toset(var.data_source_account_ids)

  statement_id   = "AllowExecutionFromAppAccounts"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.datasrc.function_name
  principal      = "arn:aws:iam::${each.value}:root"
  source_account = each.value
}
