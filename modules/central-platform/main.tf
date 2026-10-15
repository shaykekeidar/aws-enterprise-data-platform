
data "aws_caller_identity" "current" {}

locals {
  name_prefix = "enterprise-data-lake-${var.environment}"
}

module "data_lake" {
  source = "../s3-data-lake"

  bucket_name = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}"

  kms_key_arn = aws_kms_key.data_lake.arn

  enable_lifecycle     = var.enable_lifecycle
  allowed_cors_origins = []
}
