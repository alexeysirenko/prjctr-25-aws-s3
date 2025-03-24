variable "region" {
  type    = string
  default = "eu-central-1"
  description = "AWS region"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}