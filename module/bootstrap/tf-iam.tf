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
#
# DO NOT USE "AdministratorAccess" as it is done here!
#
resource "aws_iam_role_policy_attachment" "tf_role_attachment" {
  role       = aws_iam_role.tf_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
