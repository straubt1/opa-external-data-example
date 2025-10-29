# Infrastructure Setup

This directory contains Terraform configuration to create an AWS S3 bucket that hosts external data for OPA policies.

## Overview

The infrastructure creates:
- An S3 bucket with versioning enabled
- Public access configuration to allow reading the data file
- A bucket policy that grants public read access to `data.json`
- Upload of the `data.json` file to the bucket

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- AWS account with permissions to create S3 buckets

## Configuration

The setup uses the following variables (see `variables.tf`):

- `aws_region` - AWS region for the bucket (default: `us-east-1`)
- `bucket_prefix` - Prefix for the bucket name (default: `opa-external-data-`)
- `data_file_name` - Name of the JSON file to upload (default: `data.json`)

## Data File Structure

The `data.json` file contains policy configuration data including:

- **allowed_instance_types**: List of EC2 instance types that are permitted
- **allowed_regions**: List of AWS regions where resources can be created
- **required_tags**: Tags that must be present on resources
- **cost_limits**: Budget constraints and hourly cost limits
- **compliance**: Security and compliance requirements

This data is consumed by OPA policies to make policy decisions.

## Deployment

### Initialize Terraform

```bash
cd infrastructure
terraform init
```

### Plan the deployment

```bash
terraform plan
```

### Apply the configuration

```bash
terraform apply
```

### Get the public URL

After successful deployment, Terraform will output the public HTTPS URL where the JSON file can be accessed:

```bash
terraform output data_file_url
```

Example output:
```
https://opa-external-data-abc123.s3.us-east-1.amazonaws.com/data.json
```

## Verify Public Access

You can verify the file is publicly accessible using curl:

```bash
curl $(terraform output -raw data_file_url)
```

Or visit the URL in a web browser.

## Updating the Data File

To update the data in the JSON file:

1. Edit `data.json` with your changes
2. Update the `last_updated` field with the current date
3. Run `terraform apply` to upload the new version

Terraform will detect the change (via MD5 hash) and upload the updated file.

## Clean Up

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: This will permanently delete the S3 bucket and all its contents.

## Security Considerations

⚠️ **Warning**: This configuration makes the `data.json` file publicly readable. This is intentional for the demo but should be carefully considered for production use cases.

For production:
- Consider using signed URLs or authentication
- Implement bucket encryption
- Use CloudFront for CDN and additional security
- Enable server access logging
- Implement lifecycle policies for cost management

## Troubleshooting

### Public access blocked

If you encounter errors about public access being blocked, ensure:
1. The `aws_s3_bucket_public_access_block` resource settings are correct
2. Your AWS account doesn't have organization-level policies blocking public buckets
3. The bucket policy is applied after the public access block settings

### File not uploading

If the file isn't uploading:
1. Verify `data.json` exists in the infrastructure directory
2. Check file permissions
3. Review Terraform logs for specific errors
