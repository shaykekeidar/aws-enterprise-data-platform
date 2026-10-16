variable "central_bucket_arn" {
  description = "ARN of the Central Data Lake S3 bucket"
  type        = string
}
variable "central_kms_key_arn" {
  description = "ARN of the Central Data Lake KMS key"
  type        = string
}