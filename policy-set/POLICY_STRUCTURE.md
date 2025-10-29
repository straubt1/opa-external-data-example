# OPA Policy Structure

This document explains the OPA policy structure used in this project, following HashiCorp's recommended patterns.

## Overview

The policy implementation follows the pattern used in HashiCorp's [tf-compliance-opa-demo](https://github.com/hashicorp/tf-compliance-opa-demo) repository, which provides a structured approach to OPA policies for Terraform Cloud.

## Key Differences from Basic OPA Policies

### 1. **Input Format**

Terraform Cloud provides input in the format `input.plan.resource_changes[]` rather than `input.planned_values`:

```json
{
  "plan": {
    "resource_changes": [
      {
        "address": "aws_instance.example",
        "type": "aws_instance",
        "mode": "managed",
        "change": {
          "actions": ["create"],
          "after": { ... }
        }
      }
    ]
  }
}
```

### 2. **Policy Query Format**

Instead of querying a simple boolean (`allow`) or array (`violations`), policies return structured **rule objects**:

```hcl
# policies.hcl
policy "instance_type_validation" {
  description       = "Ensure that only allowed EC2 instance types are used"
  query             = "data.terraform.policies.external_data_policy.instance_types_rule"
  enforcement_level = "mandatory"
}
```

### 3. **Rule Object Structure**

Each rule returns a structured object containing:

```json
{
  "policy": "Policy Name",
  "description": "Detailed description of the violation",
  "severity": "high|medium|low",
  "resources": {
    "count": 2,
    "addresses": ["aws_instance.example1", "aws_instance.example2"],
    "details": [
      {
        "address": "aws_instance.example1",
        "instance_type": "m5.xlarge",
        "allowed_types": ["t2.micro", "t2.small"]
      }
    ]
  }
}
```

### 4. **Multiple Policies**

You can define multiple independent policies in `policies.hcl`:

```hcl
policy "instance_type_validation" {
  description       = "Ensure that only allowed EC2 instance types are used"
  query             = "data.terraform.policies.external_data_policy.instance_types_rule"
  enforcement_level = "mandatory"
}

policy "required_tags_validation" {
  description       = "Ensure that all resources have required tags"
  query             = "data.terraform.policies.external_data_policy.required_tags_rule"
  enforcement_level = "mandatory"
}
```

## Policy Evaluation

### How Terraform Cloud Evaluates Policies

1. **Empty Set = Pass**: If a rule query returns an empty set `[]`, the policy passes
2. **Non-Empty Set = Fail**: If a rule query returns any objects, the policy fails and displays the violation details
3. **Enforcement Levels**:
   - `advisory`: Violations shown as warnings, run continues
   - `mandatory`: Violations block the run (can be overridden by authorized users)
   - `hard-mandatory`: Violations block the run (cannot be overridden)

### Example Flow

```rego
# If no violations exist, rule returns empty set
instance_types_rule[result] {
    count(instance_type_violations) != 0  # Only true if violations exist
    result := {
        "policy": "Instance Type Validation",
        "description": "...",
        "resources": { ... }
    }
}

# Terraform Cloud evaluation:
# - No violations → rule = [] → PASS ✅
# - Has violations → rule = [{...}] → FAIL ❌
```

## Alternative: Deny Pattern

For simpler policies, you can also use the `deny` pattern which returns an array of error messages:

```rego
deny contains msg {
    some resource in violations
    msg := sprintf("Resource '%s' violates policy", [resource.address])
}
```

Query in `policies.hcl`:
```hcl
query = "data.terraform.policies.external_data_policy.deny"
```

## Benefits of This Approach

1. **Rich Error Information**: Provides detailed context about violations
2. **Multiple Policies**: Can separate concerns into independent policy checks
3. **Flexible Enforcement**: Different policies can have different enforcement levels
4. **Better User Experience**: Users see structured, actionable feedback in Terraform Cloud UI

## Testing

Test files should use the same `input.plan.resource_changes` format:

```rego
test_policy_fails_on_violation if {
    violations := rule with input as {
        "plan": {
            "resource_changes": [...]
        }
    }
    count(violations) > 0
}
```

## References

- [HashiCorp OPA Demo Repository](https://github.com/hashicorp/tf-compliance-opa-demo)
- [Terraform Cloud OPA Integration Docs](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement/opa)
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
