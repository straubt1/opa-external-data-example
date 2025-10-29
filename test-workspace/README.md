# Test Workspace

This directory contains Terraform configurations to test the OPA external data policy in HCP Terraform.

## Overview

The configurations demonstrate both **passing** and **failing** scenarios for OPA policy validation:

- **Passing Example**: Resources that comply with all policy rules
- **Failing Example**: Resources that violate policy rules (controlled by variables)

## OPA Policy Rules

The policy validates against external data from S3 and enforces:

### 1. Instance Type Validation
**Allowed types** (from S3 data):
- `t2.micro`
- `t2.small`
- `t3.micro`
- `t3.small`

### 2. Region Validation
**Allowed regions** (from S3 data):
- `us-east-1`
- `us-west-2`
- `eu-west-1`

### 3. Required Tags
All resources must have:
- `Environment`
- `Owner`
- `Project`

## Test Scenarios

### Scenario 1: Passing Configuration (Default)

```hcl
create_passing_example = true
create_failing_example = false
```

**Resources created:**
- `aws_instance.passing_example` - t2.micro with all required tags
- `aws_instance.passing_small` - t3.small with all required tags

**Expected OPA Result:** ✅ **PASS** - All checks succeed

### Scenario 2: Failing Configuration

```hcl
create_passing_example = false
create_failing_example = true
```

**Resources created:**
- `aws_instance.failing_example` - m5.xlarge (not allowed) and missing tags

**Expected OPA Result:** ❌ **FAIL** with violations:
- Instance type 'm5.xlarge' is not in allowed list
- Missing required tag: Owner
- Missing required tag: Project

### Scenario 3: Mixed Configuration

```hcl
create_passing_example = true
create_failing_example = true
```

**Expected OPA Result:** ❌ **FAIL** - The failing resources will cause policy failure

## Local Testing

### Test Passing Scenario

```bash
cd test-workspace

# Option 1: Use default (passing only)
terraform plan

# Option 2: Explicit variables
terraform plan -var="create_passing_example=true" -var="create_failing_example=false"
```

### Test Failing Scenario

```bash
# Enable failing resources
terraform plan -var="create_passing_example=false" -var="create_failing_example=true"
```

## HCP Terraform CLI Workflow

### Prerequisites

1. Complete the setup in `../setup/`
2. Set your HCP Terraform token:
   ```bash
   export TFE_TOKEN="your-token"
   ```

### Configure the Workspace

1. Uncomment the `cloud` block in `main.tf`:

```hcl
cloud {
  organization = "your-org-name"
  workspaces {
    name = "opa-external-data-demo"
  }
}
```

2. Initialize Terraform:

```bash
terraform init
```

### Run Plans with Policy Checks

#### Test Passing Scenario

```bash
# Create only passing resources
terraform plan -var="create_passing_example=true" -var="create_failing_example=false"
```

**Expected Output:**
```
Plan: 2 to add, 0 to change, 0 to destroy

Policy check results:
  ✅ opa-external-data-validation - passed
```

#### Test Failing Scenario

```bash
# Create failing resources
terraform plan -var="create_passing_example=false" -var="create_failing_example=true"
```

**Expected Output:**
```
Plan: 1 to add, 0 to change, 0 to destroy

Policy check results:
  ❌ opa-external-data-validation - failed
  
  Violations:
    - Instance type 'm5.xlarge' for resource 'aws_instance.failing_example' 
      is not in the allowed list: ["t2.micro", "t2.small", "t3.micro", "t3.small"]
    - Resource aws_instance.failing_example is missing required tag: Owner
    - Resource aws_instance.failing_example is missing required tag: Project
```

## Resource Details

### Passing Example (`aws_instance.passing_example`)

```hcl
ami           = "ami-0c55b159cbfafe1f0"
instance_type = "t2.micro"              # ✅ In allowed list

tags = {
  Environment = "development"            # ✅ Required tag
  Owner       = "platform-team"          # ✅ Required tag
  Project     = "opa-demo"               # ✅ Required tag
}
```

**Why it passes:**
- Instance type `t2.micro` is in the allowed list from S3
- Region `us-east-1` is in the allowed regions
- All required tags are present

### Failing Example (`aws_instance.failing_example`)

```hcl
ami           = "ami-0c55b159cbfafe1f0"
instance_type = "m5.xlarge"             # ❌ NOT in allowed list

tags = {
  Environment = "production"             # ✅ Has Environment
  # ❌ Missing Owner tag
  # ❌ Missing Project tag
}
```

**Why it fails:**
- Instance type `m5.xlarge` is NOT in the allowed list from S3
- Missing required tags: `Owner` and `Project`

## Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region (must be allowed) | `us-east-1` |
| `ami_id` | AMI ID for instances | `ami-0c55b159cbfafe1f0` |
| `create_passing_example` | Create passing resources | `true` |
| `create_failing_example` | Create failing resources | `false` |
| `create_additional_resources` | Create S3 buckets for testing | `false` |

## Testing Workflow

### 1. Test Locally First

```bash
# Test passing scenario
terraform plan -var="create_failing_example=false"

# Test failing scenario
terraform plan -var="create_failing_example=true"
```

### 2. Test in HCP Terraform

```bash
# Ensure cloud block is configured
terraform init

# Run plan (triggers OPA policy check)
terraform plan
```

### 3. Review Policy Results

Check the HCP Terraform UI or CLI output for:
- Policy check status (passed/failed)
- Specific violations (if any)
- External data fetch status

## Modifying Test Cases

### Add a New Passing Resource

```hcl
resource "aws_instance" "my_passing_test" {
  ami           = var.ami_id
  instance_type = "t3.micro"  # Must be in allowed list
  
  tags = {
    Environment = "test"       # Required
    Owner       = "my-team"    # Required
    Project     = "my-project" # Required
  }
}
```

### Add a New Failing Resource

```hcl
resource "aws_instance" "my_failing_test" {
  ami           = var.ami_id
  instance_type = "c5.large"  # NOT in allowed list
  
  tags = {
    Name = "Test Instance"
    # Missing required tags
  }
}
```

## Updating External Data

To change policy rules:

1. Edit `../infrastructure/data.json`
2. Re-apply infrastructure: `cd ../infrastructure && terraform apply`
3. OPA policy will automatically fetch updated data on next run

## Troubleshooting

### Policy not being evaluated

**Check:**
- Policy set is configured in HCP Terraform
- Policy set is attached to the workspace
- Policy files are uploaded to the policy set

### Policy always passes

**Check:**
- `create_failing_example` variable is set to `true`
- External data URL is correct in policy
- S3 bucket is publicly accessible

### AWS credentials error

**Check:**
- AWS credentials are configured (environment variables or AWS CLI)
- Credentials have permission to create EC2 instances
- Region is valid and accessible

## Clean Up

### Local Testing

```bash
# No resources are created during plan
# Nothing to clean up
```

### After Actual Apply

```bash
terraform destroy
```

## Next Steps

1. Test both scenarios locally
2. Configure HCP Terraform cloud block
3. Run plans in HCP Terraform
4. Observe policy check results
5. Modify external data and test again

## Resources

- [HCP Terraform CLI Workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/cli)
- [OPA Policy Enforcement](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/opa)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
