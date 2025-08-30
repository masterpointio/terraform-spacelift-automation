# Look up all spaces in order to map space names to space IDs
data "spacelift_spaces" "all" {}

# Look up all worker pools in order to map worker pool names to IDs
data "spacelift_worker_pools" "all" {}

# Validate the runtime overrides against the schema
# Frustrating that we have to do this, but this successfully validates the typing
# of the given runtime overrides since we need to use `any` for the variable type :(
# See https://github.com/masterpointio/terraform-spacelift-automation/pull/44 for full details
data "jsonschema_validator" "runtime_overrides" {
  for_each = var.runtime_overrides

  document = jsonencode(each.value)
  schema   = "${path.module}/stack-config.schema.json"
}
