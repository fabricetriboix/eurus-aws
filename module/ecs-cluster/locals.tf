data "aws_caller_identity" "current" {
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  cluster_name = "${var.org}-${var.project}-${var.env}-${var.cluster_name_suffix}"
  kms_alias    = "ecs-cluster-${local.cluster_name}"

  tags = {
    ModuleSource = "modules/ecs-cluster"
  }
}
