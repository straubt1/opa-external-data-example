variable "aws_region" {
  description = "AWS region where the S3 bucket will be created"
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name (bucket name will be auto-generated)"
  type        = string
  default     = "opa-external-data-"
}

variable "data_file_name" {
  description = "Name of the JSON data file to upload to S3"
  type        = string
  default     = "data.json"
}
