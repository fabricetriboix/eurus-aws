locals {
  table_name = "${var.org}-${var.project}-${var.realm}-tf-locks-${var.region}"
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enable      = true
    kms_key_arn = module.key.arn
  }

  tags = {
    Name    = local.table_name
    Purpose = "Store OpenTofu state locks for the ${var.realm} realm"
  }
}
