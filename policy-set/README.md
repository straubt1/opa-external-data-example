# OPA Policy Set

This directory contains Open Policy Agent (OPA) policies written in Rego that demonstrate fetching external data from AWS S3 and using it for policy enforcement in HCP Terraform.

## Overview

The policy set includes:

- **`external_data_policy.rego`**: Main policy that fetches data from S3 and validates Terraform plans
- **`external_data_policy_test.rego`**: Unit tests for the policy
- **`policies.hcl`**: HCP Terraform Policy Set configuration
- **`test-data/`**: Sample input data for local testing

## Policy Logic

The `external_data_policy.rego` performs the following validations:

### 1. Instance Type Validation
- Fetches allowed instance types from external S3 JSON file
- Validates that all `aws_instance` resources use allowed instance types
- **Passes if**: All instances use types from the allowed list
- **Fails if**: Any instance uses a non-allowed type

### 2. Region Validation
- Checks that resources are created in allowed regions
- **Passes if**: All resources are in allowed regions
- **Fails if**: Any resource is in a non-allowed region

### 3. Required Tags Validation
- Ensures all taggable resources have required tags
- **Passes if**: All resources have all required tags
- **Fails if**: Any resource is missing required tags

### External Data Structure

The policy expects external data in the following format:

```json
{
  "allowed_instance_types": ["t2.micro", "t2.small", ...],
  "allowed_regions": ["us-east-1", "us-west-2", ...],
  "required_tags": ["Environment", "Owner", "Project"]
}
```

## Local Testing

### Prerequisites

Install OPA CLI:

```bash
# macOS
brew install opa

# Linux
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_darwin_amd64
chmod +x opa
sudo mv opa /usr/local/bin/

# Verify installation
opa version
```

### Running Unit Tests

Run the built-in unit tests:

```bash
cd policy-set
opa test policies/ -v
```

Expected output:
```
policies/external_data_policy_test.rego:
  data.terraform.policies.external_data_policy.test_valid_configuration: PASS
  data.terraform.policies.external_data_policy.test_invalid_instance_type: PASS
  data.terraform.policies.external_data_policy.test_missing_required_tags: PASS
```

### Testing with Mock Data (Offline)

Test the policy with mock external data (no S3 call):

```bash
# Test passing scenario
opa eval \
  --data policies/external_data_policy.rego \
  --data test-data/mock-external-data.json \
  --input test-data/passing-input.json \
  --format pretty \
  'data.terraform.policies.external_data_policy.deny'

# Test failing scenario
opa eval \
  --data policies/external_data_policy.rego \
  --data test-data/mock-external-data.json \
  --input test-data/failing-input.json \
  --format pretty \
  'data.terraform.policies.external_data_policy.deny'
```

### Testing with Live S3 Data

Test the policy with actual external data from S3:

```bash
# Evaluate passing scenario
opa eval \
  --data policies/external_data_policy.rego \
  --input test-data/passing-input.json \
  --format pretty \
  'data.terraform.policies.external_data_policy.deny'

# Evaluate failing scenario
opa eval \
  --data policies/external_data_policy.rego \
  --input test-data/failing-input.json \
  --format pretty \
  'data.terraform.policies.external_data_policy.deny'
```

### Interactive Policy Development

Start an interactive REPL for policy development:

```bash
opa run policies/external_data_policy.rego test-data/mock-external-data.json
```

In the REPL, you can query the policy:
```
> data.terraform.policies.external_data_policy.external_data
> data.terraform.policies.external_data_policy.deny
```

## HCP Terraform Integration

### Creating a Policy Set

1. **Create a new Policy Set** in HCP Terraform:
   - Go to Organization Settings → Policy Sets
   - Click "Create a new policy set"
   - Choose "Version control" or "Upload"

2. **Configure the Policy Set**:
   - Name: `external-data-validation`
   - Description: Validates Terraform configurations against external data
   - Policy framework: **OPA**
   - Workspaces: Select the workspaces to apply this policy to

3. **Upload Policy Files**:
   - Upload `policies.hcl`
   - Upload the `policies/` directory with all `.rego` files

### Policy Set Configuration

The `policies.hcl` file defines the policies:

```hcl
policy "instance_type_validation" {
  description       = "Ensure that only allowed EC2 instance types are used"
  query             = "data.terraform.policies.external_data_policy.instance_types_rule"
  enforcement_level = "advisory"
}

policy "required_tags_validation" {
  description       = "Ensure that all resources have required tags"
  query             = "data.terraform.policies.external_data_policy.required_tags_rule"
  enforcement_level = "advisory"
}
```

**Enforcement Levels**:
- `advisory`: Policy failures will be logged but won't block runs
- `mandatory`: Policy failures will block the run

### Updating the S3 URL

Before deploying to HCP Terraform, update the S3 URL in `external_data_policy.rego`:

```rego
external_data_url := "https://YOUR-BUCKET-NAME.s3.REGION.amazonaws.com/data.json"
```

Replace with your actual S3 bucket URL from the infrastructure deployment.

## Policy Output

The policy provides two main outputs:

1. **`deny` set** - Contains violation messages:
```json
[
  "Instance type 'm5.xlarge' for resource 'aws_instance.failing_example' is not in allowed list: [...]",
  "Resource 'aws_instance.failing_example' is missing required tag: Owner"
]
```

2. **`rule` set** - Contains structured violation details:
```json
{
  "policy": "Instance Type Validation",
  "description": "Found 1 resource(s) with invalid instance types...",
  "severity": "high",
  "resources": {
    "count": 1,
    "addresses": [...],
    "details": [...]
  }
}
```

## Troubleshooting

### External data not loading

If external data is not loading:

1. Verify the S3 URL is correct in `external_data_policy.rego`
2. Check that the S3 bucket allows public read access
3. Test the URL manually: `curl https://your-bucket-url/data.json`
4. Check HCP Terraform's network access to the S3 bucket
5. Review OPA logs for HTTP request errors

### Policy always passes/fails

1. Review the policy logic in the REPL
2. Check the input data structure matches expected format
3. Verify external data structure is correct
4. Run unit tests to isolate issues

### Tests failing

1. Ensure OPA is up to date: `opa version`
2. Check mock data matches external data structure
3. Review test assertions in `external_data_policy_test.rego`

## Extending the Policy

To add additional validations:

1. Add new fields to the external data JSON file
2. Create new validation rules in the policy
3. Add corresponding unit tests
4. Update this documentation

Example additions:
- AMI validation
- Cost limit checks
- Compliance requirements
- Resource count limits

## Best Practices

- **Version external data**: Include a version field and update it when changing structure
- **Cache considerations**: OPA may cache HTTP responses; consider cache headers
- **Error handling**: The policy uses `raise_error: false` to gracefully handle S3 unavailability
- **Testing**: Always test policies locally before deploying to HCP Terraform
- **Documentation**: Keep violation messages clear and actionable

## Resources

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [OPA Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [HCP Terraform OPA Integration](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/opa)
- [OPA HTTP Built-in Function](https://www.openpolicyagent.org/docs/latest/policy-reference/#http)
