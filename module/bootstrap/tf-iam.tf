data "aws_iam_policy_document" "tf_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.management_github_role_arn]
    }
  }
}

resource "aws_iam_role" "tf_role" {
  name               = "tf-role-${var.region}"
  assume_role_policy = data.aws_iam_policy_document.tf_role_assume_policy.json

  tags = merge(local.tags, {
    Name    = "tf-role-${var.region}"
    Purpose = "Allow OpenTofu to deploy resources to this account"
  })
}

# NB: You will need to tighten the OpenTofu policy according to your compliance and security requirements.
data "aws_iam_policy_document" "tf_role_policy" {
  statement {
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tf_role_policy" {
  name   = "tf-role-policy-${var.region}"
  policy = data.aws_iam_policy_document.tf_role_policy.json
}

resource "aws_iam_role_policy_attachment" "tf_role_attachment" {
  role       = aws_iam_role.tf_role.name
  policy_arn = aws_iam_policy.tf_role_policy.arn
}
