provider "aws" {
  region = var.region
}

# Base bucket resource
resource "aws_s3_bucket" "immutable_bucket" {
  bucket = var.bucket_name
  
  # Enable object lock when creating the bucket
  object_lock_enabled = true
}

# Set ownership controls instead of ACL
resource "aws_s3_bucket_ownership_controls" "immutable_bucket_ownership" {
  bucket = aws_s3_bucket.immutable_bucket.id
  
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "immutable_bucket_versioning" {
  bucket = aws_s3_bucket.immutable_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Object lock configuration
resource "aws_s3_bucket_object_lock_configuration" "immutable_bucket_lock_config" {
  bucket = aws_s3_bucket.immutable_bucket.id
  
  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 30
    }
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "immutable_bucket_block" {
  bucket                  = aws_s3_bucket.immutable_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}