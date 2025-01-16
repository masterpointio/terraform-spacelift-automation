# Source: https://docs.spacelift.io/concepts/policy/terraform-plan-policy#organizational-rule-enforcement
package spacelift

deny[sprintf(message, [resource.address])] {
  message := "static AWS credentials are evil (%s)"
  resource := input.terraform.resource_changes[_]
  resource.change.actions[_] == "create"
  resource.type == "aws_iam_access_key"
}
