# Tests for the per-stack `stack_settings.name` override.
#
# By default a stack's Spacelift name is the derived config key: "<root_module>-<workspace>"
# under MultiInstance and "<root_module>" under SingleInstance. `stack_settings.name` lets a
# single stack override that without renaming its directory or YAML file, which would change
# the Terraform resource key and force a destroy/create.

mock_provider "spacelift" {
  mock_data "spacelift_spaces" {
    defaults = {
      spaces = []
    }
  }

  mock_data "spacelift_worker_pools" {
    defaults = {
      worker_pools = []
    }
  }

  mock_data "spacelift_aws_integrations" {
    defaults = {
      integrations = []
    }
  }
}

mock_provider "jsonschema" {
  mock_data "jsonschema_validator" {
    defaults = {
      validated = "{}"
    }
  }
}

variables {
  workspace_prefix_enabled = false
  repository               = "terraform-spacelift-automation"
  github_enterprise = {
    namespace = "masterpointio"
  }
  aws_integration_enabled = false
}

run "test_multi_instance_stack_name_override_is_used_when_specified" {
  command = plan

  variables {
    root_modules_discovery_path = "./tests/fixtures/stack-name-override"
    project_root_prefix         = "tests/fixtures/stack-name-override"
    root_module_structure       = "MultiInstance"
    all_root_modules_enabled    = true
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-prod"].name == "Root Module A :: Production"
    error_message = "stack_settings.name should override the derived stack name: ${spacelift_stack.default["root-module-a-prod"].name}"
  }

  # The override changes only the Spacelift name, never the resource key or project_root.
  assert {
    condition     = spacelift_stack.default["root-module-a-prod"].project_root == "tests/fixtures/stack-name-override/root-module-a"
    error_message = "stack_settings.name should not affect project_root: ${spacelift_stack.default["root-module-a-prod"].project_root}"
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-dev"].name == "root-module-a-dev"
    error_message = "Stack without a name override should fall back to the derived key: ${spacelift_stack.default["root-module-a-dev"].name}"
  }
}

run "test_single_instance_stack_name_override_is_used_when_specified" {
  command = plan

  variables {
    root_modules_discovery_path = "./tests/fixtures/stack-name-override"
    project_root_prefix         = "tests/fixtures/stack-name-override"
    root_module_structure       = "SingleInstance"
    all_root_modules_enabled    = true
  }

  assert {
    condition     = spacelift_stack.default["root-module-b"].name == "Root Module B :: Single"
    error_message = "stack_settings.name should override the derived name under SingleInstance: ${spacelift_stack.default["root-module-b"].name}"
  }
}
