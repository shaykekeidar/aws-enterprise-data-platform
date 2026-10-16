# Assumes an existing Glue execution role:
# aws_iam_role.office_c_glue
#
# The bucket and KMS ARNs are supplied as variables.

# Glue execution role - Office C DEV
resource "aws_iam_role" "office_c_glue" {
  name = "office-c-glue-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy_document" "office_c_glue_io" {
  statement {
    sid = "ListOfficeCStaging"

    actions = ["s3:ListBucket"]

    resources = [
      var.office_c_staging_bucket_arn
    ]
  }

  statement {
    sid = "ReadOfficeCStaging"

    actions = ["s3:GetObject"]

    resources = [
      "${var.office_c_staging_bucket_arn}/*"
    ]
  }

  statement {
    sid = "DecryptOfficeCStaging"

    actions = ["kms:Decrypt"]

    resources = [
      var.office_c_staging_kms_arn
    ]
  }

  statement {
    sid = "WriteMaskedDataToCentral"

    actions = ["s3:PutObject"]

    resources = [
      "${var.central_bucket_arn}/incoming/office-c/*"
    ]
  }

  statement {
    sid = "EncryptCentralData"

    actions = ["kms:GenerateDataKey"]

    resources = [
      var.central_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "office_c_glue_io" {
  name   = "office-c-glue-io"
  role   = aws_iam_role.office_c_glue.id
  policy = data.aws_iam_policy_document.office_c_glue_io.json
}
