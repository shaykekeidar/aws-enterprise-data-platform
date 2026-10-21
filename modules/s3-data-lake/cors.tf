resource "aws_s3_bucket_cors_configuration" "data_lake" {
  count = length(var.allowed_cors_origins) > 0 ? 1 : 0

  bucket = aws_s3_bucket.data_lake.id

  cors_rule {
    id = "office-a-browser-upload"

    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = var.allowed_cors_origins

    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
