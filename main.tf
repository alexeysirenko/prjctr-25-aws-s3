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
