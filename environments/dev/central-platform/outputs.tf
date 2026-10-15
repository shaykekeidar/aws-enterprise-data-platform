output "data_lake_bucket_arn" {
  description = "DEV Data Lake S3 bucket ARN"
  value       = module.central_platform.data_lake_bucket_arn
}

output "data_lake_bucket_name" {
  description = "DEV Data Lake S3 bucket name"
  value       = module.central_platform.data_lake_bucket_name
}