# Policy Set Parameters
# These can be overridden when attaching the policy set to workspaces in HCP Terraform
param "external_data_url" {
  description = "URL to fetch external policy data (S3 bucket URL)"
  type        = "string"
  default     = "https://opa-external-data-20251029174057804100000001.s3.us-east-1.amazonaws.com/data.json"
}

policy "instance_type_validation" {
  description       = "Ensure that only allowed EC2 instance types are used"
  query             = "data.terraform.policies.external_data_policy.instance_types_rule"
  enforcement_level = "advisory"
  # Parameters are automatically passed to the policy via input.global
}

policy "required_tags_validation" {
  description       = "Ensure that all resources have required tags"
  query             = "data.terraform.policies.external_data_policy.required_tags_rule"
  enforcement_level = "advisory"
  # Parameters are automatically passed to the policy via input.global
}
