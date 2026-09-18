mock_provider "spacelift" {
  mock_data "spacelift_spaces" { defaults = { spaces = [] } }
  mock_data "spacelift_worker_pools" { defaults = { worker_pools = [] } }
  mock_data "spacelift_aws_integrations" { defaults = { integrations = [] } }
}

mock_provider "jsonschema" {
  mock_data "jsonschema_validator" { defaults = { validated = "{}" } }
}

variables {
  workspace_prefix_enabled = false
  repository               = "terraform-spacelift-automation"
  github_enterprise = {
    namespace = "masterpointio"
  }
}

# Stack configs may be grouped into subdirectories under stacks/, e.g. one directory per tenant
# for single-tenant infrastructure. The subdirectory is organizational only: it groups files in
# Git and in the Spacelift UI folder label, but contributes nothing to the stack or workspace name.
run "test_stack_subdirectories_are_discovered" {
  command = plan

  variables {
    root_modules_discovery_path  = "./tests/fixtures/single-tenant-multi-instance"
    all_root_modules_enabled     = true
    default_tf_workspace_enabled = false
  }

  assert {
    condition = toset(keys(spacelift_stack.default)) == toset([
      "tenant-infra-acme-prod",
      "tenant-infra-acme-stage",
      "tenant-infra-globex-prod",
      "tenant-infra-globex-stage",
    ])
    error_message = "Unexpected stacks: ${jsonencode(keys(spacelift_stack.default))}"
  }

  # The root module is resolved from the path before stacks/, not from the tenant subdirectory.
  assert {
    condition     = spacelift_stack.default["tenant-infra-acme-prod"].project_root == "./tests/fixtures/single-tenant-multi-instance/tenant-infra"
    error_message = "project_root incorrect: ${spacelift_stack.default["tenant-infra-acme-prod"].project_root}"
  }

  # The tenant subdirectory must not leak into the workspace name; Terraform rejects "/" there.
  assert {
    condition     = spacelift_stack.default["tenant-infra-acme-prod"].terraform_workspace == "acme-prod"
    error_message = "Workspace incorrect: ${spacelift_stack.default["tenant-infra-acme-prod"].terraform_workspace}"
  }

  # Two stacks in the same tenant subdirectory resolve independently.
  assert {
    condition     = spacelift_stack.default["tenant-infra-acme-stage"].terraform_workspace == "acme-stage"
    error_message = "Workspace incorrect: ${spacelift_stack.default["tenant-infra-acme-stage"].terraform_workspace}"
  }

  # tfvars/ mirrors the stacks/ layout, so the copied file keeps the tenant subdirectory.
  assert {
    condition     = contains(spacelift_stack.default["tenant-infra-globex-stage"].before_init, "cp tfvars/globex/globex-stage.tfvars spacelift.auto.tfvars")
    error_message = "tfvars copy incorrect: ${jsonencode(spacelift_stack.default["tenant-infra-globex-stage"].before_init)}"
  }

  # The folder label keeps the full structure so stacks group by tenant in the Spacelift UI.
  assert {
    condition     = contains(spacelift_stack.default["tenant-infra-globex-prod"].labels, "folder:tenant-infra/globex/globex-prod")
    error_message = "Folder label incorrect: ${jsonencode(spacelift_stack.default["tenant-infra-globex-prod"].labels)}"
  }

  # The module-level common.yaml still merges into every stack, at any subdirectory depth.
  assert {
    condition     = alltrue([for s in keys(spacelift_stack.default) : contains(spacelift_stack.default[s].labels, "tenant_infra_common_label")])
    error_message = "common.yaml not merged into all stacks"
  }
}
