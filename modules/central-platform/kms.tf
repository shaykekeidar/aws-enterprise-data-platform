resource "aws_kms_key" "data_lake" {
  description             = "KMS key for DEV Data Lake"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
