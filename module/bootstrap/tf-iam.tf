data "aws_iam_policy_document" "tf_role_assume_policy" {
  count = var.management_github_role_arn != null ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.management_github_role_arn]
    }
  }
}

resource "aws_iam_role" "tf_role" {
  count = var.management_github_role_arn != null ? 1 : 0

  name               = "tf-role"
  assume_role_policy = data.aws_iam_policy_document.tf_role_assume_policy[0].json

  tags = merge(local.tags, {
    Name    = "tf-role"
    Purpose = "Allow OpenTofu to deploy resources to this account"
  })
}

# NB: You will need to tighten the OpenTofu policy according to your compliance and security requirements.
resource "aws_iam_role_policy_attachment" "tf_role_attachment" {
  count = var.management_github_role_arn != null ? 1 : 0

  # checkov:skip=CKV_AWS_274
  role       = aws_iam_role.tf_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
