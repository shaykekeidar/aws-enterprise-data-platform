module "central_platform" {
  source = "../../../modules/central-platform"

  name_prefix      = "enterprise-data-lake-dev"
  environment      = var.environment
  enable_lifecycle = var.enable_lifecycle

  office_a_presign_role_arn = var.office_a_presign_role_arn
  office_c_glue_role_arn    = var.office_c_glue_role_arn
}