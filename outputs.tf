output "bucket_name" {
  description = "Name of the S3 bucket used to store ECR-related artifacts"
  value       = module.ecr_bucket.s3_bucket_id
}
