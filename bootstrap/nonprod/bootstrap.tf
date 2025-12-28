module "bootstrap" {
  source = "git::https://github.com/fabricetriboix/eurus-aws.git//modules/bootstrap?ref=feat-bootstrap"

  org     = "myorg"
  project = "myproject"
  realm   = "nonprod"
}
