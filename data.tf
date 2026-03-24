# Look up data sources in order to map [NAME] to [ID]
data "spacelift_spaces" "all" {}
data "spacelift_worker_pools" "all" {}
data "spacelift_aws_integrations" "all" {}

# Look up unique Spacelift role slugs needed for role attachments.
# We use for_each over the set of unique slugs so each slug is resolved only once,
# even if many stacks share the same role.
data "spacelift_role" "attachments" {
  for_each = local._external_role_attachment_slugs
  slug     = each.key
}

# Validate the runtime overrides against the schema
# Frustrating that we have to do this, but this successfully validates the typing
# of the given runtime overrides since we need to use `any` for the variable type :(
# See https://github.com/masterpointio/terraform-spacelift-automation/pull/44 for full details
data "jsonschema_validator" "runtime_overrides" {
  for_each = var.runtime_overrides

  document = jsonencode(each.value)
  schema   = "${path.module}/stack-config.schema.json"
}
