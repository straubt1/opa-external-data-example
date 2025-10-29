terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket for hosting external data
resource "aws_s3_bucket" "external_data" {
  bucket_prefix = var.bucket_prefix

  tags = {
    Name        = "OPA External Data Bucket"
    Purpose     = "Demo"
    Environment = "Development"
  }
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "external_data" {
  bucket = aws_s3_bucket.external_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access settings - we need to allow public access for this demo
resource "aws_s3_bucket_public_access_block" "external_data" {
  bucket = aws_s3_bucket.external_data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access to the data.json file
resource "aws_s3_bucket_policy" "external_data" {
  bucket = aws_s3_bucket.external_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.external_data.arn}/${var.data_file_name}"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.external_data]
}

# Upload the data.json file to S3
resource "aws_s3_object" "data_file" {
  bucket       = aws_s3_bucket.external_data.id
  key          = var.data_file_name
  source       = "${path.module}/${var.data_file_name}"
  content_type = "application/json"
  etag         = filemd5("${path.module}/${var.data_file_name}")

  tags = {
    Name = "OPA Policy External Data"
  }

  depends_on = [aws_s3_bucket_policy.external_data]
}
