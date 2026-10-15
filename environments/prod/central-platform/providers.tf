provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-enterprise-data-platform"
      Environment = "prod"
      Office      = "central-platform"
      CostCenter  = "shared-platform"
      ManagedBy   = "Terraform"
    }
  }
}