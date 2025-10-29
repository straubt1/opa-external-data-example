output "passing_instance_id" {
  description = "ID of the passing example instance"
  value       = var.create_passing_example ? aws_instance.passing_example[0].id : null
}

output "passing_instance_arn" {
  description = "ARN of the passing example instance"
  value       = var.create_passing_example ? aws_instance.passing_example[0].arn : null
}

output "policy_compliance_summary" {
  description = "Summary of which resources comply with OPA policies"
  value = {
    passing_example = {
      created         = var.create_passing_example
      instance_type   = "t2.micro"
      has_all_tags    = true
      expected_result = "✅ PASS - Complies with all policy rules"
    }
    failing_example = {
      created         = var.create_failing_example
      instance_type   = "m5.xlarge"
      has_all_tags    = false
      expected_result = "❌ FAIL - Violates instance type and missing tags"
    }
  }
}
