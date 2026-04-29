locals {
  aws_integration_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.aws_integration_enabled, var.aws_integration_enabled)
  }

  # Per-side AWS integration ID resolution.
  # Fallback chain (first non-null wins):
  #   stack-level per-side id → stack-level per-side name →
  #   stack-level generic id  → stack-level generic name  →
  #   module-level per-side id → module-level per-side name →
  #   module-level generic id  → module-level generic name  → null
  _aws_integration_read_ids = {
    for stack in local.stacks : stack => try(coalesce(
      try(local.stack_configs[stack].aws_integration_read_id, null),
      try(local.name_to_id_mappings.aws_integration[local.stack_configs[stack].aws_integration_read_name], null),
      try(local.stack_configs[stack].aws_integration_id, null),
      try(local.name_to_id_mappings.aws_integration[local.stack_configs[stack].aws_integration_name], null),
      var.aws_integration_read_id,
      try(local.name_to_id_mappings.aws_integration[var.aws_integration_read_name], null),
      var.aws_integration_id,
      try(local.name_to_id_mappings.aws_integration[var.aws_integration_name], null),
    ), null)
  }

  _aws_integration_write_ids = {
    for stack in local.stacks : stack => try(coalesce(
      try(local.stack_configs[stack].aws_integration_write_id, null),
      try(local.name_to_id_mappings.aws_integration[local.stack_configs[stack].aws_integration_write_name], null),
      try(local.stack_configs[stack].aws_integration_id, null),
      try(local.name_to_id_mappings.aws_integration[local.stack_configs[stack].aws_integration_name], null),
      var.aws_integration_write_id,
      try(local.name_to_id_mappings.aws_integration[var.aws_integration_write_name], null),
      var.aws_integration_id,
      try(local.name_to_id_mappings.aws_integration[var.aws_integration_name], null),
    ), null)
  }

  # Flatten into the map consumed by spacelift_aws_integration_attachment.
  #
  # Key strategy (preserves backward-compatibility):
  #   - Same integration for both sides (the pre-existing default case):
  #       key = "<stack>" — identical to the v2 for_each key, so no state churn on upgrade.
  #   - Different integrations per side:
  #       keys = "<stack>::read" and/or "<stack>::write"
  #
  # Null on either side means no attachment is created for that side.
  aws_integration_attachments = merge([
    for stack in keys(local.aws_integration_stacks) : (
      local._aws_integration_read_ids[stack] != null
      && local._aws_integration_read_ids[stack] == local._aws_integration_write_ids[stack]
    ) ? {
      # Combined: single attachment, both flags true, bare stack key preserved from v2.
      (stack) = {
        stack          = stack
        integration_id = local._aws_integration_read_ids[stack]
        read           = true
        write          = true
      }
    } : merge(
      local._aws_integration_read_ids[stack] != null ? {
        "${stack}::read" = {
          stack          = stack
          integration_id = local._aws_integration_read_ids[stack]
          read           = true
          write          = false
        }
      } : {},
      local._aws_integration_write_ids[stack] != null ? {
        "${stack}::write" = {
          stack          = stack
          integration_id = local._aws_integration_write_ids[stack]
          read           = false
          write          = true
        }
      } : {},
    )
  ]...)
}

resource "spacelift_aws_integration_attachment" "default" {
  for_each = local.aws_integration_attachments

  integration_id = each.value.integration_id
  stack_id       = spacelift_stack.default[each.value.stack].id
  read           = each.value.read
  write          = each.value.write
}
