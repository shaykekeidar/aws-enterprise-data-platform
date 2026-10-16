data "aws_caller_identity" "central" {}

data "aws_iam_policy_document" "data_lake_kms" {
  statement {
    sid       = "EnableCentralAccountIAM"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.central.account_id}:root"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(compact([
      var.office_a_presign_role_arn,
      var.office_c_glue_role_arn
    ])) > 0 ? [1] : []

    content {
      sid     = "AllowExternalOfficeWritesThroughS3"
      effect  = "Allow"

      actions = [
        "kms:GenerateDataKey"
      ]

      resources = ["*"]

      principals {
        type = "AWS"
        identifiers = compact([
          var.office_a_presign_role_arn,
          var.office_c_glue_role_arn
        ])
      }

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.eu-north-1.amazonaws.com"]
      }
    }
  }
}

resource "aws_kms_key" "data_lake" {
  description             = "KMS key for DEV Data Lake"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.data_lake_kms.json
}