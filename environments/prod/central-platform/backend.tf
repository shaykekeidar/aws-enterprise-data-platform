
terraform {
  backend "s3" {
    bucket       = "enterprise-data-platform-tfstate-057461015409"
    key          = "prod/central-platform/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
