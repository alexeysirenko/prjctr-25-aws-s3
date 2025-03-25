provider "aws" {
  region = var.region
}

# Base bucket resource
resource "aws_s3_bucket" "immutable_bucket" {
  bucket = var.bucket_name
  
  # Enable object lock when creating the bucket
  object_lock_enabled = true
}

resource "aws_s3_bucket_versioning" "immutable_bucket_versioning" {
  bucket = aws_s3_bucket.immutable_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }

  depends_on = [aws_s3_bucket.immutable_bucket]
}

# Object lock configuration
resource "aws_s3_bucket_object_lock_configuration" "immutable_bucket_lock_config" {
  bucket = aws_s3_bucket.immutable_bucket.id
  
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 3
    }
  }

  depends_on = [aws_s3_bucket_versioning.immutable_bucket_versioning]
}

resource "aws_s3_bucket_lifecycle_configuration" "versioning_cleanup" {
  bucket = aws_s3_bucket.immutable_bucket.id

  rule {
    id = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 4  # One day more than the retention period
    }
  }

  depends_on = [aws_s3_bucket_object_lock_configuration.immutable_bucket_lock_config]
}

# Public access block
resource "aws_s3_bucket_public_access_block" "immutable_bucket_block" {
  bucket                  = aws_s3_bucket.immutable_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_lifecycle_configuration.versioning_cleanup]
}

##### LOGS

# Log bucket resource
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.bucket_name}-logs"
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }

  depends_on = [aws_s3_bucket.log_bucket]
}

resource "aws_s3_bucket_public_access_block" "log_bucket_block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_versioning.log_bucket_versioning]
}

resource "aws_s3_bucket_logging" "immutable_bucket_logging" {
  bucket = aws_s3_bucket.immutable_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "s3-access-logs/"

  depends_on = [aws_s3_bucket.log_bucket]
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.log_bucket.arn}/s3-access-logs/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.immutable_bucket.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.log_bucket_block]
}

# Get current account ID for bucket policy
data "aws_caller_identity" "current" {}

# Optional: Lifecycle configuration for log bucket to manage log retention
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    expiration {
      days = 90  # Keep logs for 90 days
    }
  }

  depends_on = [aws_s3_bucket_versioning.log_bucket_versioning]
}


