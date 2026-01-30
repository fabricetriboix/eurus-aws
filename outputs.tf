output "bucket" {
  description = "Name of the bucket where the TF states are stored"
  value       = module.tf_bucket.s3_bucket_id
}

output "logs_bucket" {
  description = "Name of the bucket where the access logs for the TF states bucket are stored"
  value       = module.logs_bucket.s3_bucket_id
}

output "kms_alias" {
  description = "Alias of the KMS key used to encrypt the S3 bucket"
  value       = "alias/${local.kms_alias}"
}
