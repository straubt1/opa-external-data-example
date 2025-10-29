policy "external-data-validation" {
  enforcement_level = "mandatory"
  query             = "data.terraform.policies.external_data_policy.policy_result"
}
