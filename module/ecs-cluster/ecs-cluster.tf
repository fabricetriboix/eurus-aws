resource "aws_cloudwatch_log_group" "logs" {
  name       = "/${var.org}/${var.project}/${var.env}/ecs-cluster-logs"
  kms_key_id = module.key.key_id

  # checkov:skip=CKV_AWS_338:Retention of less than one year is allowed
  retention_in_days = var.log_retention_days

  tags = merge(local.tags, {
    Name = "/${var.org}/${var.project}/${var.env}/ecs-cluster-logs"
  })
}

resource "aws_ecs_cluster" "cluster" {
  # checkov:skip=CKV_AWS_65:Container Insights is disabled at cluster level because the ECS metrics are already collected by the ADOT sidecar containers.
  name   = local.cluster_name
  region = var.region

  configuration {
    managed_storage_configuration {
      kms_key_id                           = module.kms.key_id
      fargate_ephemeral_storage_kms_key_id = module.kms.key_id
    }

    execute_command_configuration {
      kms_key_id = module.kms.key_id
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.logs.name
      }
    }
  }

  setting {
    # NB: Container Insights is disabled at cluster level because the ECS metrics are already collected by the ADOT sidecar containers.
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(local.tags, {
    Name = local.cluster_name
  })
}
