
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  count = var.enable_lifecycle ? 1 : 0 # so I won't apply this file.

  bucket = aws_s3_bucket.data_lake.id

  depends_on = [
    aws_s3_bucket_versioning.data_lake
  ]

  # INCOMING DATA - OFFICE A AND B
  rule {
    id     = "incoming-intelligent-tiering"
    status = "Enabled"

    filter {
      prefix = "incoming/"
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  # CURATED DATA - PROCESSED DATA FROM ALL OFFICES
  rule {
    id     = "curated-intelligent-tiering"
    status = "Enabled"

    filter {
      prefix = "curated/"
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  # REGULATORY ARCHIVE
  rule {
    id     = "archive-deep-archive"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "temporary-expiration"
    status = "Enabled"

    filter {
      prefix = "temporary/"
    }

    # Expire the current object after 7 days.
    expiration {
      days = 7
    }

    # Permanently delete noncurrent versions
    # after they have been noncurrent for 7 days.
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  # Remove obsolete delete markers when no
  # object versions remain.
  rule {
    id     = "temporary-expired-delete-markers"
    status = "Enabled"

    filter {
      prefix = "temporary/"
    }

    expiration {
      expired_object_delete_marker = true
    }
  }


  # CLEAN UP INCOMPLETE UPLOADS
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}