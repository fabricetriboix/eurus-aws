module "ecs_cluster" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//?ref=module-ecs-cluster-v1.0.0"
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git//module/ecs-cluster?ref=fix-ecs-cluster"

  org                 = var.org
  project             = var.project
  env                 = var.env
  region              = var.region
  cluster_name_suffix = "plf"
  logs_retention_days = var.logs_retention_days
}
