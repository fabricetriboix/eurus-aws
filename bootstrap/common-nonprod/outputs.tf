output "bucket" {
  description = "Name of the bucket where the TF states are stored"
  value       = module.bootstrap.bucket
}

output "logs_bucket" {
  description = "Name of the bucket where the access logs for the TF states bucket are stored"
  value       = module.bootstrap.logs_bucket
}

output "lock_table" {
  description = "Name of the DynamoDB table where TF locks are managed"
  value       = module.bootstrap.lock_table
}

output "kms_alias" {
  description = "Alias of the KMS key used to encrypt the S3 buckets and the DynamoDB table"
  value       = module.bootstrap.kms_alias
}
