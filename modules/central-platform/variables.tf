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