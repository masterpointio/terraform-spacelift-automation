output "spacelift_stacks" {
  description = <<-EOT
  A map of Spacelift stacks with selected attributes.
  To reduce the risk of accidentally exporting sensitive data, only a subset of attributes is exported.
  EOT
  value = {
    for name, stack in spacelift_stack.default : name => {
      id         = stack.id
      labels     = stack.labels
      autodeploy = stack.autodeploy
    }
  }
}

output "spacelift_roles" {
  description = "A map of managed Spacelift roles created by this module, keyed by the var.managed_roles map key."
  value = {
    for key, role in spacelift_role.managed : key => {
      id          = role.id
      slug        = role.slug
      name        = role.name
      description = role.description
      actions     = role.actions
    }
  }
}

output "spacelift_roles" {
  description = "A map of managed Spacelift roles created by this module, keyed by the var.managed_roles map key."
  value = {
    for key, role in spacelift_role.managed : key => {
      id          = role.id
      slug        = role.slug
      name        = role.name
      description = role.description
      actions     = role.actions
    }
  }
}

output "spacelift_spaces" {
  description = "A map of Spacelift spaces with all their attributes."
  value = {
    for name, space in spacelift_space.default : name => space
  }
}
