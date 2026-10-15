variable "bucket_name" {
  description = "Unique name for the central S3 Data Lake bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for Data Lake encryption"
  type        = string
}

# I don't want to apply lifecycle policies due to money spending.
variable "enable_lifecycle" {
  description = "Enable S3 lifecycle policies"
  type        = bool
  default     = false
}

# for cors handling
variable "allowed_cors_origins" {
  description = "Approved browser origins for direct S3 uploads"
  type        = list(string)
  default     = []
}