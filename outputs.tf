output "spacelift_stacks" {
  description = <<-EOT
  A map of Spacelift stacks with selected attributes.
  To reduce the risk of accidentally exporting sensitive data, only a subset of attributes is exported.
  EOT
  value = {
    for name, stack in spacelift_stack.default : name => {
      id             = stack.id
      labels         = stack.labels
      autodeploy     = stack.autodeploy
      administrative = stack.administrative
    }
  }
}
