# Tests for the project_root_prefix variable
# This variable allows setting a global prefix for project_root when root_modules_path
# uses relative paths for local scanning but the repo structure is different.

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
  repository = "terraform-spacelift-automation"
  github_enterprise = {
    namespace = "masterpointio"
  }
  aws_integration_enabled = false
}

# Test default behavior without project_root_prefix (null)
# project_root should be calculated from root_modules_path with "../" stripped
run "test_project_root_without_prefix" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/multi-instance"
    all_root_modules_enabled = true
  }

  # project_root should be based on root_modules_path
  assert {
    condition     = spacelift_stack.default["root-module-a-test"].project_root == "./tests/fixtures/multi-instance/root-module-a"
    error_message = "Project root without prefix should use root_modules_path: ${spacelift_stack.default["root-module-a-test"].project_root}"
  }
}

# Test project_root_prefix with relative root_modules_path
# This is the main use case: local scanning with relative paths, but different repo structure
run "test_project_root_with_prefix" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/multi-instance"
    project_root_prefix      = "terraform/root-modules"
    all_root_modules_enabled = true
  }

  # project_root should use the prefix instead of the stripped root_modules_path
  assert {
    condition     = spacelift_stack.default["root-module-a-test"].project_root == "terraform/root-modules/root-module-a"
    error_message = "Project root with prefix should use project_root_prefix: ${spacelift_stack.default["root-module-a-test"].project_root}"
  }
}

# Test that project_root_prefix works with nested directories
run "test_project_root_prefix_with_nested_directories" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/nested-multi-instance"
    project_root_prefix      = "infra/terraform/modules"
    root_module_structure    = "MultiInstance"
    all_root_modules_enabled = true
  }

  # project_root should preserve nested path with the prefix
  assert {
    condition     = spacelift_stack.default["parent/nested-dev"].project_root == "infra/terraform/modules/parent/nested"
    error_message = "Nested project_root with prefix incorrect: ${spacelift_stack.default["parent/nested-dev"].project_root}"
  }
}

# Test that per-stack project_root in YAML takes precedence over project_root_prefix
run "test_stack_project_root_takes_precedence_over_prefix" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/multi-instance"
    project_root_prefix      = "should/be/ignored"
    all_root_modules_enabled = true
  }

  # Stack with custom project_root in YAML should use that, not the prefix
  assert {
    condition     = spacelift_stack.default["root-module-a-custom-project-root"].project_root == "custom/path/to/root-module-a"
    error_message = "Per-stack project_root should take precedence over prefix: ${spacelift_stack.default["root-module-a-custom-project-root"].project_root}"
  }

  # Stack without custom project_root should use the prefix
  assert {
    condition     = spacelift_stack.default["root-module-a-test"].project_root == "should/be/ignored/root-module-a"
    error_message = "Stack without custom project_root should use prefix: ${spacelift_stack.default["root-module-a-test"].project_root}"
  }
}

# Test that project_root_prefix works with SingleInstance structure
run "test_project_root_prefix_with_single_instance" {
  command = plan

  variables {
    root_module_structure    = "SingleInstance"
    root_modules_path        = "./tests/fixtures/single-instance"
    project_root_prefix      = "terraform/single"
    all_root_modules_enabled = true
  }

  assert {
    condition     = spacelift_stack.default["root-module-a"].project_root == "terraform/single/root-module-a"
    error_message = "SingleInstance project_root with prefix incorrect: ${spacelift_stack.default["root-module-a"].project_root}"
  }
}

# Test that project_root_prefix replaces the fallback behavior that strips "../"
# This validates the main use case: root_modules_path with "../" for local scanning,
# project_root_prefix for the actual repo path
run "test_project_root_prefix_replaces_fallback" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/multi-instance"
    project_root_prefix      = "actual/repo/path"
    all_root_modules_enabled = true
  }

  # With prefix set, the fallback logic is bypassed entirely
  assert {
    condition     = spacelift_stack.default["root-module-a-test"].project_root == "actual/repo/path/root-module-a"
    error_message = "Prefix should replace fallback entirely: ${spacelift_stack.default["root-module-a-test"].project_root}"
  }
}
