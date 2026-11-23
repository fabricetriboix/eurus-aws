data "aws_caller_identity" "current" {}

locals {
  # This is the management account
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:fabricetriboix/eurus-aws:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-role-${var.org}-${var.project}"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json

  tags = {
    Name    = "github-actions-role-${var.org}-${var.project}"
    Purpose = "Allow GitHub workflows to assume this role to deploy OpenTofu configurations"
  }
}

data "aws_iam_policy_document" "assume_subaccounts" {
  statement {
    actions = ["sts:AssumeRole"]

    resources = flatten([
      for account in var.accounts : "arn:aws:iam::${account.id}:role/tf-role-${var.org}-${var.project}"
    ])
  }
}

resource "aws_iam_policy" "assume_subaccounts" {
  name   = "tf-assume-subaccount-${var.org}-${var.project}"
  policy = data.aws_iam_policy_document.assume_subaccounts.json

  tags = {
    Name = "tf-assume-subaccount-${var.org}-${var.project}"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_role_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.assume_subaccounts.arn
}
