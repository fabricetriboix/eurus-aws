data "aws_iam_policy_document" "allow_assume_tf_roles" {
    statement {
        actions = ["sts:AssumeRole"]

        resources = [for account_id in var.children_account_ids : "arn:aws:iam::${account_id}:role/eurus-aws-tf-role"]
    }
}

resource "aws_iam_policy" "allow_assume_tf_roles" {
    name = "${var.org}-${var.project}-${local.account_type}-${var.realm}-allow-assume-tf-roles"
    policy = data.aws_iam_policy_document.allow_assume_tf_roles.json

    tags = merge(local.tags, {
        Name = "${var.org}-${var.project}-${local.account_type}-${var.realm}-allow-assume-tf-roles"
    })
}

resource "aws_iam_role" "tf_role" {
    name = "${var.org}-${var.project}-${local.account_type}-${var.realm}-tf-role"
    assume_role_policy = data.aws_iam_policy_document.allow_assume_tf_roles.json

    tags = merge(local.tags, {
        Name = "${var.org}-${var.project}-${local.account_type}-${var.realm}-tf-role"
    })
}