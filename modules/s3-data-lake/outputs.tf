output "bucket_id" {
  description = "S3 Data Lake bucket ID"
  value       = aws_s3_bucket.data_lake.id
}

output "bucket_arn" {
  description = "S3 Data Lake bucket ARN"
  value       = aws_s3_bucket.data_lake.arn

}