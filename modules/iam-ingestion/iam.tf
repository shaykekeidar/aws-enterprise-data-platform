
# ============================================
# Lambda Trust Policy
# ============================================

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ============================================
# Office A - CSV Validation Lambda Role
# ============================================

resource "aws_iam_role" "office_a_validator" {
  name = "${var.name_prefix}-office-a-validator"

  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# ============================================
# Office A - S3 and KMS Permissions
# ============================================

data "aws_iam_policy_document" "office_a_validator" {

  statement {
    sid = "ReadIncomingCSV"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      "${var.data_lake_bucket_arn}/incoming/office-a/*"
    ]
  }

  statement {
    sid = "WriteValidatedFiles"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${var.data_lake_bucket_arn}/raw/office-a/*",
      "${var.data_lake_bucket_arn}/quarantine/office-a/*"
    ]
  }

  statement {
    sid = "DeleteProcessedIncoming"

    actions = [
      "s3:DeleteObject"
    ]

    resources = [
      "${var.data_lake_bucket_arn}/incoming/office-a/*"
    ]
  }

  statement {
    sid = "UseDataLakeKMS"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "office_a_validator" {
  name   = "${var.name_prefix}-office-a-validator-policy"
  role   = aws_iam_role.office_a_validator.id
  policy = data.aws_iam_policy_document.office_a_validator.json
}

# ============================================
# CloudWatch Logs
# ============================================

resource "aws_iam_role_policy_attachment" "office_a_logs" {
  role = aws_iam_role.office_a_validator.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
