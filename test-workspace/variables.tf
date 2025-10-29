variable "aws_region" {
  description = "AWS region for resources (must be in allowed regions: us-east-1, us-west-2, eu-west-1)"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instances"
  type        = string
  # Default: Amazon Linux 2 AMI in us-east-1 (update based on your region)
  default = "ami-0c55b159cbfafe1f0"
}

variable "create_passing_example" {
  description = "Whether to create the passing example resources"
  type        = bool
  default     = true
}

variable "create_failing_example" {
  description = "Whether to create the failing example resources (will violate OPA policy)"
  type        = bool
  default     = true
}

variable "create_additional_resources" {
  description = "Whether to create additional test resources (S3 buckets)"
  type        = bool
  default     = true
}
