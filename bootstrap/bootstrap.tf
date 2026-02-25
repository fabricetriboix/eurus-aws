module "bootstrap" {
  # checkov:skip=CKV_TF_1,CKV_TF_2:False positives
  source = "git::https://github.com/fabricetriboix/eurus-aws.git?ref=module-bootstrap-v0.2.0"

  org       = "myorg"
  project   = "myproject"
  realm     = "nonprod"
  is_common = true
}
