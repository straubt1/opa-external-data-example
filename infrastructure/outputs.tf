output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.external_data.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.external_data.arn
}

output "data_file_url" {
  description = "Public HTTPS URL to access the data.json file"
  value       = "https://${aws_s3_bucket.external_data.bucket_regional_domain_name}/${var.data_file_name}"
}

output "data_file_s3_uri" {
  description = "S3 URI of the data file"
  value       = "s3://${aws_s3_bucket.external_data.id}/${var.data_file_name}"
}
