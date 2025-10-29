package terraform.policies.external_data

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

# Test: Valid configuration should pass
test_valid_configuration if {
    allow with input as mock_passing_input
        with external_data as mock_external_data
}

# Test: Invalid instance type should fail
test_invalid_instance_type if {
    not allow with input as mock_invalid_instance_type_input
        with external_data as mock_external_data
}

# Test: Missing required tags should fail
test_missing_required_tags if {
    not allow with input as mock_missing_tags_input
        with external_data as mock_external_data
}

# Test: Violations should be populated for invalid instance type
test_violations_invalid_instance if {
    count(violations) > 0 with input as mock_invalid_instance_type_input
        with external_data as mock_external_data
}

# Mock input - Passing scenario
mock_passing_input := {
    "planned_values": {
        "root_module": {
            "resources": [
                {
                    "address": "aws_instance.example",
                    "type": "aws_instance",
                    "name": "example",
                    "values": {
                        "instance_type": "t2.micro",
                        "tags": {
                            "Environment": "dev",
                            "Owner": "team-a",
                            "Project": "demo"
                        }
                    },
                    "provider_config": {
                        "expressions": {
                            "region": {
                                "constant_value": "us-east-1"
                            }
                        }
                    }
                }
            ]
        }
    }
}

# Mock input - Invalid instance type
mock_invalid_instance_type_input := {
    "planned_values": {
        "root_module": {
            "resources": [
                {
                    "address": "aws_instance.invalid",
                    "type": "aws_instance",
                    "name": "invalid",
                    "values": {
                        "instance_type": "m5.large",
                        "tags": {
                            "Environment": "dev",
                            "Owner": "team-a",
                            "Project": "demo"
                        }
                    },
                    "provider_config": {
                        "expressions": {
                            "region": {
                                "constant_value": "us-east-1"
                            }
                        }
                    }
                }
            ]
        }
    }
}

# Mock input - Missing required tags
mock_missing_tags_input := {
    "planned_values": {
        "root_module": {
            "resources": [
                {
                    "address": "aws_instance.missing_tags",
                    "type": "aws_instance",
                    "name": "missing_tags",
                    "values": {
                        "instance_type": "t2.micro",
                        "tags": {
                            "Environment": "dev"
                        }
                    },
                    "provider_config": {
                        "expressions": {
                            "region": {
                                "constant_value": "us-east-1"
                            }
                        }
                    }
                }
            ]
        }
    }
}
