module "ecs_cluster" {
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git//?ref=feature-ecs-cluster-v0.1.0"
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//module/ecs-cluster?ref=feat-ecs-cluster"

  org                 = var.org
  project             = var.project
  env                 = var.env
  region              = var.region
  cluster_name_suffix = "plf"
  log_retention_days  = var.log_retention_days
}
