resource "aws_s3_bucket" "data_lake" {
  bucket = var.bucket_name

  tags = {
    Name      = var.bucket_name
    Component = "DataLake"
  }
}

data "aws_iam_policy_document" "data_lake_security" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.data_lake.arn,
      "${aws_s3_bucket.data_lake.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    condition {
      test     = "Bool"
      variable = "aws:PrincipalIsAWSService"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyOutdatedTLS"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.data_lake.arn,
      "${aws_s3_bucket.data_lake.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }

    condition {
      test     = "Bool"
      variable = "aws:PrincipalIsAWSService"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUploadsOutsideApprovedPrefixes"
    effect = "Deny"

    actions = ["s3:PutObject"]

    not_resources = [
      "${aws_s3_bucket.data_lake.arn}/incoming/*",
      "${aws_s3_bucket.data_lake.arn}/curated/*",
      "${aws_s3_bucket.data_lake.arn}/quarantine/*",
      "${aws_s3_bucket.data_lake.arn}/archive/*",
      "${aws_s3_bucket.data_lake.arn}/raw/*",
      "${aws_s3_bucket.data_lake.arn}/temporary/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  # Include the Office A permission only when a real role ARN is configured.
  dynamic "statement" {
    for_each = var.office_a_presign_role_arn == null ? [] : [var.office_a_presign_role_arn]

    content {
      sid     = "AllowOfficeAPresignedUpload"
      effect  = "Allow"
      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.data_lake.arn}/incoming/office-a/*"
      ]

      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
    }
  }

  # Include the Office C permission only when a real role ARN is configured.
  dynamic "statement" {
    for_each = var.office_c_glue_role_arn == null ? [] : [var.office_c_glue_role_arn]

    content {
      sid     = "AllowOfficeCMaskedUpload"
      effect  = "Allow"
      actions = ["s3:PutObject"]

      resources = [
        "${aws_s3_bucket.data_lake.arn}/incoming/office-c/*"
      ]

      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  policy = data.aws_iam_policy_document.data_lake_security.json
}

resource "aws_s3_bucket_ownership_controls" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}