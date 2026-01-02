locals {
  table_name = "${var.org}-${var.project}-${local.type}-${var.realm}-tf-locks-${local.region}"
}

resource "aws_dynamodb_table" "tf_locks" {
  # checkov:skip=CKV_AWS_28: Point in time recovery is not necessary for this
  # DynamoDB table. It holds only OpenTofu locks and it does not make sense to
  # restore such locks from the past.

  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # checkov:skip=CKV_AWS_119:False positive
  server_side_encryption {
    enabled     = true
    kms_key_arn = module.key.key_arn
  }

  tags = merge(local.tags, {
    Name    = local.table_name
    Purpose = "Store OpenTofu state locks for the ${var.realm} realm"
  })
}
