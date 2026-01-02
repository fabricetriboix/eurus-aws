output "bucket" {
  description = "Name of the bucket where the TF states are stored"
  value       = module.tf_bucket.s3_bucket_id
}

output "logs_bucket" {
  description = "Name of the bucket where the access logs for the TF states bucket are stored"
  value       = module.logs_bucket.s3_bucket_id
}

output "lock_table" {
  description = "Name of the DynamoDB table where TF locks are managed"
  value       = aws_dynamodb_table.tf_locks.name
}

output "kms_alias" {
  description = "Alias of the KMS key used to encrypt the S3 buckets and the DynamoDB table"
  value       = "alias/${local.kms_alias}"
}
