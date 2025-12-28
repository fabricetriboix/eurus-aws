module "bootstrap" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/eurus-aws.git/?ref=modules-bootstrap-v0.1.2"

  org     = "myorg"
  project = "myproject"
  realm   = "nonprod"
}
