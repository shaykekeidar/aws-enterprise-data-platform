data "aws_iam_policy_document" "office_a_presign" {
  statement {
    sid     = "UploadOfficeAOnly"
    actions = ["s3:PutObject"]

    resources = [
      "${var.central_bucket_arn}/incoming/office-a/*"
    ]
  }

  statement {
    sid     = "EncryptWithCentralKMS"
    actions = ["kms:GenerateDataKey"]

    resources = [
      var.central_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "office_a_presign" {
  name   = "office-a-presign"
  role   = aws_iam_role.office_a_presign.id
  policy = data.aws_iam_policy_document.office_a_presign.json
}
