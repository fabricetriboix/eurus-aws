resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id               = aws_vpc.this.id
  log_destination_type = "s3"
  log_destination      = module.vpc_flow_logs_bucket[0].s3_bucket_arn
  traffic_type         = "ALL"

  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  tags = {
    Name    = "${var.org}-${var.project}-${var.env}-vpc-flow-logs"
    Purpose = "VPC flow logs"
  }
}
