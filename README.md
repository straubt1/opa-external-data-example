# OPA External Data Example

A demonstration of using Open Policy Agent (OPA) with external data sources in HCP Terraform (Terraform Cloud). This example shows how OPA policies can fetch and use data from external REST APIs (AWS S3) for policy-based governance.

## Overview

This repository demonstrates:

1. **Infrastructure Setup**: Terraform configuration to create an AWS S3 bucket hosting a publicly-accessible JSON file
2. **OPA Policy**: Rego policy that fetches external data via HTTP and uses it for policy decisions
3. **HCP Terraform Integration**: Policy set configuration for HCP Terraform workspaces
4. **Local Testing**: Ability to test OPA policies locally before deploying to HCP Terraform

## Architecture

```
┌─────────────────────┐
│  HCP Terraform      │
│  Workspace          │
└──────────┬──────────┘
           │
           │ (Policy Evaluation)
           │
┌──────────▼──────────┐         ┌─────────────────┐
│  OPA Policy         │────────>│  AWS S3 Bucket  │
│  (Rego)             │ HTTP    │  (data.json)    │
└─────────────────────┘ GET     └─────────────────┘
```

## Repository Structure

```
.
├── README.md                 # This file
├── SPEC.md                   # Detailed specification
├── LICENSE
├── infrastructure/           # S3 bucket setup (Phase 1 ✅)
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── data.json            # External data file
│   └── README.md            # Infrastructure documentation
├── policy-set/              # OPA policies (Phase 2 ✅)
│   ├── policies.hcl         # Sentinel Policy Set configuration
│   ├── policy/
│   │   ├── external_data_policy.rego      # Main OPA policy
│   │   └── external_data_policy_test.rego # Unit tests
│   ├── test-data/           # Sample test data
│   │   ├── passing-input.json
│   │   ├── failing-input.json
│   │   └── mock-external-data.json
│   ├── test.sh              # Automated testing script
│   └── README.md
├── setup/                   # HCP Terraform setup (Phase 3 ✅)
│   ├── main.tf              # Workspace and policy set creation
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── README.md
└── test-workspace/          # Test Terraform configs (Phase 3 ✅)
    ├── main.tf              # Passing and failing examples
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── README.md
```

## Quick Start

### Phase 1: Deploy Infrastructure (Complete ✅)

1. Navigate to the infrastructure directory:

   ```bash
   cd infrastructure
   ```

2. Initialize Terraform:

   ```bash
   terraform init
   ```

3. Deploy the S3 bucket:

   ```bash
   terraform apply
   ```

4. Note the output URL where the JSON file is accessible:

   ```bash
   terraform output data_file_url
   ```

5. Verify public access:

   ```bash
   curl $(terraform output -raw data_file_url)
   ```

See [infrastructure/README.md](infrastructure/README.md) for detailed documentation.

### Phase 2: OPA Policy Development (Complete ✅)

The OPA policy is now ready and tested locally!

1. Install OPA 0.61.0:

   ```bash
   # Download OPA
   mkdir -p ~/bin
   curl -L -o ~/bin/opa https://github.com/open-policy-agent/opa/releases/download/v0.61.0/opa_darwin_amd64
   chmod +x ~/bin/opa
   ```

2. Run unit tests:

   ```bash
   cd policy-set
   ~/bin/opa test policy/ -v
   ```

3. Test with mock data (offline):

   ```bash
   ~/bin/opa eval \
     --data policy/external_data_policy.rego \
     --data test-data/mock-external-data.json \
     --input test-data/passing-input.json \
     --format pretty \
     'data.terraform.policies.external_data.policy_result'
   ```

4. Test with live S3 data:

   ```bash
   ~/bin/opa eval \
     --data policy/external_data_policy.rego \
     --input test-data/passing-input.json \
     --format pretty \
     'data.terraform.policies.external_data.policy_result'
   ```

See [policy-set/README.md](policy-set/README.md) for detailed documentation.

### Phase 3: Test Workspace (Complete ✅)

The test workspace demonstrates both passing and failing scenarios.

#### Setup HCP Terraform Workspace

1. Set your HCP Terraform token:

   ```bash
   export TFE_TOKEN="your-token"
   ```

2. Configure and create the workspace:

   ```bash
   cd setup
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your organization name
   terraform init
   terraform apply
   ```

#### Test Locally

```bash
cd test-workspace

# Test passing scenario
terraform init
terraform plan -var="create_failing_example=false"

# Test failing scenario  
terraform plan -var="create_failing_example=true"
```

#### Test in HCP Terraform

1. Configure the cloud block in `test-workspace/main.tf`
2. Run terraform init and plan
3. Observe OPA policy evaluation

See [test-workspace/README.md](test-workspace/README.md) for detailed testing scenarios.

## External Data Structure

The `data.json` file contains policy configuration including:

- **allowed_instance_types**: Permitted EC2 instance types
- **allowed_regions**: Allowed AWS regions
- **required_tags**: Mandatory resource tags
- **cost_limits**: Budget constraints
- **compliance**: Security requirements

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- OPA CLI (for local testing)
- HCP Terraform account

## Use Cases

This pattern is useful for:

- **Centralized Policy Management**: Store policy configuration externally and update without modifying policies
- **Dynamic Policy Rules**: Change policy behavior by updating external data
- **Cross-Organization Standards**: Share common policy data across multiple teams/workspaces
- **Compliance as Code**: Maintain compliance requirements in a versioned data file

## Security Considerations

⚠️ **Note**: This demo makes the S3 bucket publicly readable for simplicity. In production:

- Use authentication/authorization for external data access
- Implement bucket encryption
- Use signed URLs or CloudFront
- Enable access logging
- Regular security audits

## Contributing

See [SPEC.md](SPEC.md) for the complete specification and implementation plan.

## License

See [LICENSE](LICENSE) file for details.
