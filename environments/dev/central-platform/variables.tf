variable "aws_region" {
  description = "AWS deployment region"
  type        = string
}
variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "enable_lifecycle" {
  type    = bool
  default = false
}
variable "office_a_presign_role_arn" {
  description = "IAM role ARN for Office A presigned S3 uploads"
  type        = string
  default     = null
}

variable "office_c_glue_role_arn" {
  description = "IAM role ARN for Office C Glue ETL"
  type        = string
  default     = null
}