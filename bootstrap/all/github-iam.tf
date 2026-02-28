data "aws_caller_identity" "current" {}

locals {
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
  name               = "github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json
}

data "aws_iam_policy_document" "assume_subaccount" {
  for_each = var.accounts

  statement {
    actions = ["sts:AssumeRole"]

    resources = ["arn:aws:iam::${each.value.id}:role/tf-role-${var.region}"]
  }
}

resource "aws_iam_policy" "assume_subaccount" {
  for_each = var.accounts

  name   = "tf-assume-subaccount-${each.key}-${var.region}"
  policy = data.aws_iam_policy_document.assume_subaccount[each.key].json
}

resource "aws_iam_role_policy_attachment" "github_actions_role_policy_attachment" {
  for_each = var.accounts

  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.assume_subaccount[each.key].arn
}
