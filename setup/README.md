# HCP Terraform Workspace Setup

This directory contains Terraform configuration to set up the HCP Terraform (Terraform Cloud) workspace and project for testing OPA policies.

## Overview

This setup creates:
- An HCP Terraform project named "opa"
- A workspace for testing OPA policies
- A policy set with OPA external data validation
- (Optional) AWS credentials variable set

## Prerequisites

- HCP Terraform account
- Organization already created in HCP Terraform
- TFE token with permissions to create workspaces and policy sets
- Terraform >= 1.0 installed locally

## Setup

### 1. Set HCP Terraform Token

Export your HCP Terraform token as an environment variable:

```bash
export TFE_TOKEN="your-tfe-token-here"
```

To create a token:
1. Log in to HCP Terraform
2. Go to User Settings → Tokens
3. Create a new token

### 2. Configure Variables

Set your organization name either via variable file or command line:

**Option 1: Command line (recommended)**
```bash
# No file needed, use -var flag
terraform init
terraform apply -var="organization_name=your-org-name"
```

**Option 2: Create a terraform.tfvars file**
```bash
cat > terraform.tfvars << EOF
organization_name = "your-org-name"
EOF
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

## What Gets Created

### Project
- **Name**: `opa` (configurable)
- **Purpose**: Organize OPA-related workspaces

### Workspace
- **Name**: `opa-external-data-demo` (configurable)
- **Execution Mode**: `local` (CLI-driven workflow)
- **Auto Apply**: `false` (configurable)
- **Description**: Test workspace for OPA external data policy demonstration

### Policy Set
- **Name**: `opa-external-data-validation`
- **Type**: OPA
- **Applied To**: The created workspace
- **Policies**: Will need to be uploaded separately (see below)

## Uploading Policies to HCP Terraform

After creating the policy set, you need to upload the policy files. There are several ways to do this:

### Option 1: Using VCS (Recommended for Production)

1. Push your repository to GitHub/GitLab/Bitbucket
2. In HCP Terraform, edit the policy set
3. Connect it to your VCS repository
4. Set the policies path to `policy-set`

### Option 2: Using Terraform CLI

The policy files from the `policy-set/` directory will need to be uploaded via the HCP Terraform UI or API.

### Option 3: Using HCP Terraform UI

1. Go to your organization settings
2. Navigate to Policy Sets
3. Find `opa-external-data-validation`
4. Click "Upload new version"
5. Upload the contents of the `../policy-set/` directory

## Configuration Options

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `organization_name` | HCP Terraform organization (required) | - |
| `project_name` | Name of the project | `"opa"` |
| `workspace_name` | Name of the workspace | `"opa-external-data-demo"` |
| `auto_apply` | Auto-apply changes | `false` |
| `terraform_version` | Terraform version | `"~> 1.6"` |
| `policy_set_name` | Name of the policy set | `"opa-external-data-validation"` |
| `create_aws_variable_set` | Create AWS credentials | `false` |

### AWS Credentials (Optional)

To automatically configure AWS credentials in the workspace:

```hcl
create_aws_variable_set = true
aws_access_key_id       = "your-key"
aws_secret_access_key   = "your-secret"
```

**Note**: It's more secure to set these via environment variables or use dynamic credentials.

## Outputs

After applying, you'll see:

- `organization_name`: Your organization name
- `project_id`: ID of the created project
- `workspace_id`: ID of the created workspace
- `workspace_url`: Direct URL to the workspace
- `policy_set_id`: ID of the policy set

## Using the Workspace

After setup, you can use the workspace for testing:

1. Navigate to the test-workspace directory
2. Configure the workspace:
   ```bash
   cd ../test-workspace
   terraform init
   ```
3. Set the workspace in your local config or use CLI flags

## Clean Up

To destroy the setup:

```bash
terraform destroy
```

**Warning**: This will delete the workspace, project, and policy set.

## Troubleshooting

### "Organization not found"

Ensure:
- The organization name is correct
- Your TFE token has access to the organization
- The organization exists in HCP Terraform

### "Insufficient permissions"

Your TFE token needs:
- Permission to manage workspaces
- Permission to manage policy sets
- Organization owner or appropriate team permissions

### Policy set not showing policies

The policy set is created but policies must be uploaded separately:
1. Via VCS integration
2. Via HCP Terraform UI
3. Via API

## Next Steps

After setup:
1. Upload policies to the policy set
2. Navigate to `../test-workspace` to test configurations
3. Run Terraform plans to test policy enforcement

## Resources

- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [HCP Terraform Provider](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs)
- [OPA Policy Sets](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/opa)
