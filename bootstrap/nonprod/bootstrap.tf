module "bootstrap" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//modules/bootstrap?ref=feat-bootstrap"

  org     = "myorg"
  project = "myproject"
  realm   = "nonprod"
}
