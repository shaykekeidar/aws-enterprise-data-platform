module "central_platform" {
  source = "../../../modules/central-platform"

  name_prefix      = "enterprise-data-lake-prod"
  environment      = var.environment
  enable_lifecycle = var.enable_lifecycle
}