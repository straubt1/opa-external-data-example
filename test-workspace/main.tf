terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "terraform-tom"
    workspaces {
      name = "opa-external-data-demo"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

#############################################################################
# PASSING EXAMPLE
# This configuration complies with all OPA policy rules:
# - Uses allowed instance type (t2.micro)
# - Deployed in allowed region (us-east-1)
# - Has all required tags (Environment, Owner, Project)
#############################################################################

resource "aws_instance" "passing_example" {
  ami           = var.ami_id
  instance_type = "t2.micro" # ✅ Allowed instance type

  tags = {
    Name        = "OPA Demo - Passing Example"
    Environment = "development"   # ✅ Required tag
    Owner       = "platform-team" # ✅ Required tag
    Project     = "opa-demo"      # ✅ Required tag
    Description = "This instance passes all OPA policy checks"
  }
}

#############################################################################
# FAILING EXAMPLE
# This configuration violates OPA policy rules:
# - Uses disallowed instance type (m5.xlarge)
# - Missing required tags (Owner, Project)
#############################################################################

resource "aws_instance" "failing_example" {
  ami           = var.ami_id
  instance_type = "m5.xlarge" # ❌ NOT in allowed instance types

  tags = {
    Name        = "OPA Demo - Failing Example"
    Environment = "production" # ✅ Has Environment tag
    # ❌ Missing Owner tag
    # ❌ Missing Project tag
    Description = "This instance fails OPA policy checks"
  }
}

#############################################################################
# ADDITIONAL TEST CASES
#############################################################################

# Example: Another passing instance with different allowed type
resource "aws_instance" "passing_small" {
  count = var.create_passing_example ? 1 : 0

  ami           = var.ami_id
  instance_type = "t3.small" # ✅ Also in allowed list

  tags = {
    Name        = "OPA Demo - Small Instance"
    Environment = "staging"
    Owner       = "devops-team"
    Project     = "opa-demo"
  }
}

# Example: S3 bucket that should pass (has all required tags)
resource "aws_s3_bucket" "passing_bucket" {
  count = var.create_additional_resources ? 1 : 0

  bucket_prefix = "opa-demo-passing-"

  tags = {
    Name        = "OPA Demo Bucket"
    Environment = "development"
    Owner       = "platform-team"
    Project     = "opa-demo"
  }
}

# Example: S3 bucket that would fail (missing required tags)
resource "aws_s3_bucket" "failing_bucket" {
  count = var.create_failing_example && var.create_additional_resources ? 1 : 0

  bucket_prefix = "opa-demo-failing-"

  tags = {
    Name = "OPA Demo Failing Bucket"
    # ❌ Missing Environment, Owner, Project tags
  }
}
