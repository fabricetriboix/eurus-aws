output "bucket" {
  description = "Name of the bucket where the TF states are stored"
  value       = module.bootstrap.bucket
}

output "logs_bucket" {
  description = "Name of the bucket where the access logs for the TF states bucket are stored"
  value       = module.bootstrap.logs_bucket
}

output "kms_alias" {
  description = "Alias of the KMS key used to encrypt the S3 bucket"
  value       = module.bootstrap.kms_alias
}
