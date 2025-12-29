module "bootstrap" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  #source = "git::https://github.com/fabricetriboix/eurus-aws.git?ref=module-bootstrap-v0.1.0"
  source = "git::https://github.com/fabricetriboix/eurus-aws.git?ref=fix-bootstrap"

  org     = "myorg"
  project = "myproject"
  realm   = "nonprod"
}
