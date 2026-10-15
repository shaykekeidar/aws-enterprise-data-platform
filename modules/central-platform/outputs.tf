output "data_lake_bucket_name" {
  description = "Name of the DEV Data Lake bucket"
  value       = module.data_lake.bucket_id
}

output "data_lake_bucket_arn" {
  description = "ARN of the DEV Data Lake bucket"
  value       = module.data_lake.bucket_arn
}