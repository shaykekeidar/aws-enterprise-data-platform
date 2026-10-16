variable "office_c_staging_bucket_arn" {
  description = "ARN of Office C staging S3 bucket"
  type        = string
}

variable "office_c_staging_kms_arn" {
  description = "ARN of Office C staging KMS key"
  type        = string
}

variable "central_bucket_arn" {
  description = "ARN of the Central Data Lake S3 bucket"
  type        = string
}

variable "central_kms_key_arn" {
  description = "ARN of the Central Data Lake KMS key"
  type        = string
}