module "ecs_cluster" {
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//?ref=module-ecs-cluster-v0.1.3"
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git//module/ecs-cluster?ref=fix-ecs-cluster"

  org                 = var.org
  project             = var.project
  env                 = var.env
  region              = var.region
  cluster_name_suffix = "plf"
  log_retention_days  = var.log_retention_days
}
