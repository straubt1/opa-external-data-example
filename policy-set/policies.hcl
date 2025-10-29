policy "external-data-validation" {
  source            = "./policy/external_data_policy.rego"
  enforcement_level = "advisory"
}
