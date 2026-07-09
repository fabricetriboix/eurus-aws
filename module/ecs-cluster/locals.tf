data "aws_caller_identity" "current" {
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  kms_alias    = "ecs-cluster-${var.cluster_name}"
  cluster_name = "${var.org}-${var.project}-${var.env}"

  tags = {
    ModuleSource = "modules/ecs-cluster"
  }
}
