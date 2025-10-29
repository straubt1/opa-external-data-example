package terraform.policies.external_data_policy

import future.keywords.contains
import future.keywords.if
import future.keywords.in
import input.plan as tfplan

external_data_url := "https://opa-external-data-20251029174057804100000001.s3.us-east-1.amazonaws.com/data.json"

# Fetch external data from S3
external_data := http.send({
    "method": "GET",
    "url": external_data_url,
    "force_json_decode": true,
    "raise_error": false,
}).body

# Actions to consider for policy evaluation
actions := [
    ["no-op"],
    ["create"],
    ["update"],
]

# Helper functions to get resources
resources_by_type(type) := [resource |
    some resource in tfplan.resource_changes
    resource.type == type
    resource.mode == "managed"
    resource.change.actions in actions
]

all_taggable_resources := [resource |
    some resource in tfplan.resource_changes
    resource.mode == "managed"
    resource.change.actions in actions
    resource.change.after.tags
]

# Instance type violations
instance_type_violations := [resource |
    some resource in resources_by_type("aws_instance")
    not resource.change.after.instance_type in external_data.allowed_instance_types
]

instance_type_violators[address] {
    address := instance_type_violations[_].address
}

# Missing required tags violations
missing_tags_violations := [violation |
    some resource in all_taggable_resources
    some required_tag in external_data.required_tags
    not required_tag in object.keys(resource.change.after.tags)
    violation := {
        "address": resource.address,
        "missing_tag": required_tag,
    }
]

missing_tags_violators[address] {
    address := missing_tags_violations[_].address
}

# METADATA
# title: External Data Validation
# description: Validates AWS resources against external data policy requirements
# custom:
#  severity: high
#  enforcement_level: mandatory
# related_resources:
# - ref: https://github.com/straubt1/opa-external-data-example
# authors:
# - name: Tom Straub
# organizations:
# - HashiCorp

# Instance Type Policy Rule
instance_types_rule[result] {
    count(instance_type_violations) != 0
    result := {
        "policy": "Instance Type Validation",
        "description": sprintf("Found %d resource(s) with invalid instance types. Allowed types: %v", 
            [count(instance_type_violations), external_data.allowed_instance_types]),
        "severity": "high",
        "resources": {
            "count": count(instance_type_violations),
            "addresses": instance_type_violators,
            "details": [detail |
                some resource in instance_type_violations
                detail := {
                    "address": resource.address,
                    "instance_type": resource.change.after.instance_type,
                    "allowed_types": external_data.allowed_instance_types,
                }
            ],
        },
    }
}

# Required Tags Policy Rule
required_tags_rule[result] {
    count(missing_tags_violations) != 0
    result := {
        "policy": "Required Tags Validation",
        "description": sprintf("Found %d resource(s) missing required tags. Required tags: %v", 
            [count(missing_tags_violators), external_data.required_tags]),
        "severity": "high",
        "resources": {
            "count": count(missing_tags_violators),
            "addresses": missing_tags_violators,
            "details": missing_tags_violations,
        },
    }
}

# Combined rule result - returns violation details or empty set
rule[result] {
    result := instance_types_rule[_]
}

rule[result] {
    result := required_tags_rule[_]
}

# Deny rule - returns error messages (alternative format for simpler policies)
deny contains msg {
    some resource in instance_type_violations
    msg := sprintf("Instance type '%s' for resource '%s' is not in allowed list: %v",
        [resource.change.after.instance_type, resource.address, external_data.allowed_instance_types])
}

deny contains msg {
    some violation in missing_tags_violations
    msg := sprintf("Resource '%s' is missing required tag: %s",
        [violation.address, violation.missing_tag])
}
