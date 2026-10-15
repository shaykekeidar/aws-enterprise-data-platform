module "central_platform" {
  source = "../../../modules/central-platform"

  environment      = var.environment
  enable_lifecycle = var.enable_lifecycle
}