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
