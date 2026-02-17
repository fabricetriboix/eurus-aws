module "key" {
  count = var.enable_flow_log ? 1 : 0

  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/terraform-aws-kms.git?ref=v4.1.1-1"

  description             = "Key to encrypt VPC flow logs"
  aliases                 = [local.kms_alias]
  deletion_window_in_days = 7
  rotation_period_in_days = 90

  tags = merge(local.tags, {
    Name = "alias/${local.kms_alias}"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_log ? 1 : 0

  name              = "/${var.org}/${var.project}/${var.env}/vpc-flow-logs"
  kms_key_id        = module.key[0].key_arn
  retention_in_days = var.flow_log_retention_days

  tags = merge(local.tags, {
    Name = "/${var.org}/${var.project}/${var.env}/vpc-flow-logs"
  })
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_log_role" {
  count = var.enable_flow_log ? 1 : 0

  name               = "${var.org}-${var.project}-${var.env}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json

  tags = merge(local.tags, {
    Name = "${var.org}-${var.project}-${var.env}-flow-log-role"
  })
}

data "aws_iam_policy_document" "flow_logs" {
  count = var.enable_flow_log ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [aws_cloudwatch_log_group.flow_logs[0].arn]
  }
}

resource "aws_iam_policy" "flow_logs" {
  count = var.enable_flow_log ? 1 : 0

  name   = "${var.org}-${var.project}-${var.env}-flow-log-policy"
  policy = data.aws_iam_policy_document.flow_logs[0].json

  tags = merge(local.tags, {
    Name = "${var.org}-${var.project}-${var.env}-flow-log-policy"
  })
}

resource "aws_iam_role_policy_attachment" "flow_logs" {
  count = var.enable_flow_log ? 1 : 0

  role       = aws_iam_role.flow_log_role[0].name
  policy_arn = aws_iam_role_policy.flow_logs[0].arn
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_log ? 1 : 0

  vpc_id          = aws_vpc.this.id
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log_role[0].arn

  tags = merge(local.tags, {
    Name = "/${var.org}/${var.project}/${var.env}/vpc-flow-logs"
  })
}
