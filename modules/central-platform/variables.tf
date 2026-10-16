variable "aws_region" {
  type    = string
  default = "eu-north-1"
}
variable "environment" {
  type = string
}
variable "enable_lifecycle" {
  type    = bool
  default = false
}
variable "name_prefix" {
  description = "Prefix for AWS resource names"
  type        = string
}
variable "office_a_presign_role_arn" {
  description = "Office A presigned URL Lambda role ARN"
  type        = string
}

variable "office_c_glue_role_arn" {
  description = "Office C Glue ETL role ARN"
  type        = string
}