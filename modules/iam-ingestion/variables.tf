
variable "name_prefix" {
  description = "Resource naming prefix"
  type        = string
}

variable "data_lake_bucket_arn" {
  description = "Central S3 Data Lake bucket ARN"
  type        = string
}

variable "kms_key_arn" {
  description = "Central Data Lake KMS key ARN"
  type        = string
}