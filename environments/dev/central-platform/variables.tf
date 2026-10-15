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