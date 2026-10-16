# Central Platform IAM: Office B ingestion and shared Glue processing.
# Office A validation Lambda IAM is managed by modules/iam-ingestion.

# ------------------------------------------------------------
# Office B ingestion Lambda
# ------------------------------------------------------------
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "office_b_ingestion" {
  name               = "${var.name_prefix}-office-b-ingestion"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy_document" "office_b_ingestion" {
  statement {
    sid     = "WriteOfficeBOnly"
    actions = ["s3:PutObject"]

    resources = [
      "${module.data_lake.bucket_arn}/incoming/office-b/*"
    ]
  }

  statement {
    sid     = "EncryptWithDataLakeKey"
    actions = ["kms:GenerateDataKey"]

    resources = [
      aws_kms_key.data_lake.arn
    ]
  }
}

resource "aws_iam_role_policy" "office_b_ingestion" {
  name   = "office-b-ingestion-policy"
  role   = aws_iam_role.office_b_ingestion.id
  policy = data.aws_iam_policy_document.office_b_ingestion.json
}

resource "aws_iam_role_policy_attachment" "office_b_ingestion_logs" {
  role       = aws_iam_role.office_b_ingestion.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------
# Central data processing: AWS Glue ETL (Office B example)
# ------------------------------------------------------------
data "aws_iam_policy_document" "glue_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "data_lake_processing" {
  name               = "${var.name_prefix}-processing"
  assume_role_policy = data.aws_iam_policy_document.glue_trust.json
}

data "aws_iam_policy_document" "data_lake_processing" {
  statement {
    sid     = "ReadOfficeBIncoming"
    actions = ["s3:GetObject"]

    resources = [
      "${module.data_lake.bucket_arn}/incoming/office-b/*"
    ]
  }

  statement {
    sid     = "WriteOfficeBCurated"
    actions = ["s3:PutObject"]

    resources = [
      "${module.data_lake.bucket_arn}/curated/office_id=office-b/*"
    ]
  }

  statement {
    sid     = "ListRequiredPrefixes"
    actions = ["s3:ListBucket"]

    resources = [module.data_lake.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "incoming/office-b/",
        "incoming/office-b/*",
        "curated/office_id=office-b/",
        "curated/office_id=office-b/*"
      ]
    }
  }

  statement {
    sid = "UseDataLakeKMSKey"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [aws_kms_key.data_lake.arn]
  }
}

resource "aws_iam_role_policy" "data_lake_processing" {
  name   = "data-lake-processing-policy"
  role   = aws_iam_role.data_lake_processing.id
  policy = data.aws_iam_policy_document.data_lake_processing.json
}

# Additional Glue permissions are required when an actual Glue job is deployed
# (e.g. script/log storage, Glue Catalog operations, and CloudWatch logging).
# Grant those separately according to the specific job's resources and actions.
