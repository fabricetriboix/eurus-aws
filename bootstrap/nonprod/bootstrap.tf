module "bootstrap" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//modules/bootstrap?ref=modules-bootstrap-v0.1.0"

  org     = "myorg"
  project = "myproject"
  realm   = "nonprod"
}
