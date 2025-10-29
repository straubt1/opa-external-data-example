package terraform.policies.external_data_policy

import future.keywords.contains
import future.keywords.if

# Mock external data for testing
mock_external_data := {
    "version": "1.0.0",
    "allowed_instance_types": [
        "t2.micro",
        "t2.small",
        "t3.micro",
        "t3.small"
    ],
    "allowed_regions": [
        "us-east-1",
        "us-west-2",
        "eu-west-1"
    ],
    "required_tags": [
        "Environment",
        "Owner",
        "Project"
    ]
}

# Test: Valid configuration should have no violations
test_valid_configuration if {
    count(rule) == 0 with input as mock_passing_input
        with external_data as mock_external_data
}

# Test: Invalid instance type should create violation
test_invalid_instance_type if {
    count(instance_types_rule) > 0 with input as mock_invalid_instance_type_input
        with external_data as mock_external_data
}

# Test: Missing required tags should create violation
test_missing_required_tags if {
    count(required_tags_rule) > 0 with input as mock_missing_tags_input
        with external_data as mock_external_data
}

# Test: Violations should be detailed for invalid instance type
test_violations_invalid_instance if {
    violations := instance_types_rule with input as mock_invalid_instance_type_input
        with external_data as mock_external_data
    count(violations) == 1
    violations[_].policy == "Instance Type Validation"
    violations[_].resources.count == 1
}

# Test: Violations should be detailed for missing tags
test_violations_missing_tags if {
    violations := required_tags_rule with input as mock_missing_tags_input
        with external_data as mock_external_data
    count(violations) == 1
    violations[_].policy == "Required Tags Validation"
    violations[_].resources.count == 1
}

# Mock input - Passing scenario
mock_passing_input := {
    "plan": {
        "resource_changes": [
            {
                "address": "aws_instance.example",
                "type": "aws_instance",
                "name": "example",
                "mode": "managed",
                "change": {
                    "actions": ["create"],
                    "after": {
                        "instance_type": "t2.micro",
                        "tags": {
                            "Environment": "dev",
                            "Owner": "team-a",
                            "Project": "demo"
                        }
                    }
                }
            }
        ]
    }
}

# Mock input - Invalid instance type
mock_invalid_instance_type_input := {
    "plan": {
        "resource_changes": [
            {
                "address": "aws_instance.invalid",
                "type": "aws_instance",
                "name": "invalid",
                "mode": "managed",
                "change": {
                    "actions": ["create"],
                    "after": {
                        "instance_type": "m5.large",
                        "tags": {
                            "Environment": "dev",
                            "Owner": "team-a",
                            "Project": "demo"
                        }
                    }
                }
            }
        ]
    }
}

# Mock input - Missing required tags
mock_missing_tags_input := {
    "plan": {
        "resource_changes": [
            {
                "address": "aws_instance.missing_tags",
                "type": "aws_instance",
                "name": "missing_tags",
                "mode": "managed",
                "change": {
                    "actions": ["create"],
                    "after": {
                        "instance_type": "t2.micro",
                        "tags": {
                            "Environment": "dev"
                        }
                    }
                }
            }
        ]
    }
}
