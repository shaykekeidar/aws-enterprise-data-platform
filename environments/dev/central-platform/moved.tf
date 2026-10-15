
moved {
  from = module.data_lake
  to   = module.central_platform.module.data_lake
}

moved {
  from = aws_kms_key.data_lake
  to   = module.central_platform.aws_kms_key.data_lake
}

moved {
  from = aws_iam_role.office_b_ingestion
  to   = module.central_platform.aws_iam_role.office_b_ingestion
}

moved {
  from = aws_iam_role_policy.office_b_ingestion
  to   = module.central_platform.aws_iam_role_policy.office_b_ingestion
}

moved {
  from = aws_iam_role.data_lake_processing
  to   = module.central_platform.aws_iam_role.data_lake_processing
}

moved {
  from = aws_iam_role_policy.data_lake_processing
  to   = module.central_platform.aws_iam_role_policy.data_lake_processing
}
