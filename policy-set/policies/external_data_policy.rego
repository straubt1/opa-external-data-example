package terraform.policies.external_data

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Configuration - Update this URL with your S3 bucket URL
external_data_url := "https://opa-external-data-20251029174057804100000001.s3.us-east-1.amazonaws.com/data.json"

# Fetch external data from S3
external_data := http.send({
    "method": "GET",
    "url": external_data_url,
    "force_json_decode": true,
    "raise_error": false,
}).body

# Debug: Print external data status
debug_external_data := true {
    print("External data loaded:", external_data != null)
    print("External data content:", external_data)
}

# Default policy evaluation results
default allow := false
default valid_instance_types := false
default valid_regions := false
default required_tags_present := false

# Main policy decision
allow if {
    print("Checking policy conditions:")
    print("  valid_instance_types:", valid_instance_types)
    print("  valid_regions:", valid_regions)
    print("  required_tags_present:", required_tags_present)
    valid_instance_types
    valid_regions
    required_tags_present
}

# Check if instance types are in the allowed list
valid_instance_types if {
    count(violation_instance_types) == 0
}

violation_instance_types contains resource if {
    some resource in resources_by_type("aws_instance")
    not resource.values.instance_type in external_data.allowed_instance_types
}

# Check if resources are being created in allowed regions
valid_regions if {
    count(violation_regions) == 0
}

violation_regions contains resource if {
    some resource in all_resources
    resource.provider_config.expressions.region.constant_value
    region := resource.provider_config.expressions.region.constant_value
    not region in external_data.allowed_regions
}

# Check if required tags are present on all resources that support tags
required_tags_present if {
    count(violation_missing_tags) == 0
}

violation_missing_tags contains msg if {
    some resource in taggable_resources
    some required_tag in external_data.required_tags
    not required_tag in object.keys(resource.values.tags)
    msg := sprintf("Resource %s is missing required tag: %s", [resource.address, required_tag])
}

# Helper functions
resources_by_type(type) := [resource |
    some resource in input.planned_values.root_module.resources
    resource.type == type
]

all_resources := input.planned_values.root_module.resources

taggable_resources := [resource |
    some resource in all_resources
    resource.values.tags
]

# Policy violations for reporting
violations contains msg if {
    some resource in violation_instance_types
    msg := sprintf("Instance type '%s' for resource '%s' is not in the allowed list: %v", 
        [resource.values.instance_type, resource.address, external_data.allowed_instance_types])
}

violations contains msg if {
    some resource in violation_regions
    region := resource.provider_config.expressions.region.constant_value
    msg := sprintf("Region '%s' for resource '%s' is not in the allowed list: %v", 
        [region, resource.address, external_data.allowed_regions])
}

violations contains msg if {
    some msg in violation_missing_tags
}

# Debug: Print final results
debug_results := true {
    print("Policy evaluation complete:")
    print("  allow:", allow)
    print("  violation count:", count(violations))
    print("  violations:", violations)
}

# Policy evaluation result - must be an array for Terraform Cloud
# When policy passes (allow is true), return empty array
# When policy fails (allow is false), return array of violations
policy_result := violations
