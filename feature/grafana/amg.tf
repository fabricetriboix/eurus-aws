# Amazon Managed Grafana

resource "aws_grafana_workspace" "this" {
  name = "${var.org}-${var.project}-${var.env}"
}
