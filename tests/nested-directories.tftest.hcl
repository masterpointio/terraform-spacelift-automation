variables {
  repository = "terraform-spacelift-automation"
  github_enterprise = {
    namespace = "masterpointio"
  }
}

# Test nested directory support for MultiInstance structure
run "test_nested_directory_multi_instance_support" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/nested-multi-instance"
    all_root_modules_enabled = true
  }

  # Test that nested directories are discovered
  assert {
    condition     = contains(keys(spacelift_stack.default), "parent/nested-dev")
    error_message = "Nested directory dev stack not found: ${jsonencode(keys(spacelift_stack.default))}"
  }

  assert {
    condition     = contains(keys(spacelift_stack.default), "parent/nested-prod")
    error_message = "Nested directory prod stack not found: ${jsonencode(keys(spacelift_stack.default))}"
  }

  # Test that project_root is correct for nested directories
  assert {
    condition     = spacelift_stack.default["parent/nested-dev"].project_root == "./tests/fixtures/nested-multi-instance/parent/nested"
    error_message = "Nested directory project_root incorrect: ${spacelift_stack.default["parent/nested-dev"].project_root}"
  }

  # Test that folder labels preserve the nested structure
  assert {
    condition     = contains(spacelift_stack.default["parent/nested-dev"].labels, "folder:parent/nested/dev")
    error_message = "Nested directory folder label incorrect: ${jsonencode(spacelift_stack.default["parent/nested-dev"].labels)}"
  }

  # Test that stack names preserve forward slashes
  assert {
    condition     = spacelift_stack.default["parent/nested-dev"].name == "parent/nested-dev"
    error_message = "Nested directory stack name should preserve forward slashes: ${spacelift_stack.default["parent/nested-dev"].name}"
  }

  # Test stack-specific configuration
  assert {
    condition     = contains(spacelift_stack.default["parent/nested-dev"].labels, "nested_dev_label")
    error_message = "Nested directory dev stack should have nested_dev_label: ${jsonencode(spacelift_stack.default["parent/nested-dev"].labels)}"
  }

  assert {
    condition     = spacelift_stack.default["parent/nested-dev"].branch == "dev"
    error_message = "Nested directory dev stack should have dev branch: ${spacelift_stack.default["parent/nested-dev"].branch}"
  }

  assert {
    condition     = spacelift_stack.default["parent/nested-prod"].branch == "main"  
    error_message = "Nested directory prod stack should have main branch: ${spacelift_stack.default["parent/nested-prod"].branch}"
  }
}

# Test nested directory support for SingleInstance structure
run "test_nested_directory_single_instance_support" {
  command = plan

  variables {
    root_module_structure    = "SingleInstance"
    root_modules_path        = "./tests/fixtures/nested-single-instance"
    all_root_modules_enabled = true
  }

  # Test that nested directory is discovered
  assert {
    condition     = contains(keys(spacelift_stack.default), "parent/nested")
    error_message = "Nested single instance stack not found: ${jsonencode(keys(spacelift_stack.default))}"
  }

  # Test that project_root is correct for nested directories
  assert {
    condition     = spacelift_stack.default["parent/nested"].project_root == "./tests/fixtures/nested-single-instance/parent/nested"
    error_message = "Nested single instance project_root incorrect: ${spacelift_stack.default["parent/nested"].project_root}"
  }

  # Test that stack name preserves forward slashes for single instance
  assert {
    condition     = spacelift_stack.default["parent/nested"].name == "parent/nested"
    error_message = "Nested single instance stack name should preserve forward slashes: ${spacelift_stack.default["parent/nested"].name}"
  }

  # Test that folder labels preserve the nested structure (without workspace name for single instance)
  assert {
    condition     = contains(spacelift_stack.default["parent/nested"].labels, "folder:parent/nested")
    error_message = "Nested single instance folder label incorrect: ${jsonencode(spacelift_stack.default["parent/nested"].labels)}"
  }

  # Test stack-specific configuration
  assert {
    condition     = contains(spacelift_stack.default["parent/nested"].labels, "nested_single_label")
    error_message = "Nested single instance stack should have nested_single_label: ${jsonencode(spacelift_stack.default["parent/nested"].labels)}"
  }

  # Test that workspace is "default" for single instance
  assert {
    condition     = spacelift_stack.default["parent/nested"].terraform_workspace == "default"
    error_message = "Nested single instance should use default workspace: ${spacelift_stack.default["parent/nested"].terraform_workspace}"
  }
}

# Test that .terraform directories are filtered out
run "test_terraform_directory_filtering" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/multi-instance"
    all_root_modules_enabled = true
  }

  # Verify that no stack names contain .terraform paths
  assert {
    condition = alltrue([
      for stack_name in keys(spacelift_stack.default) :
      !can(regex("\\.terraform", stack_name))
    ])
    error_message = "Stack names should not contain .terraform paths: ${jsonencode(keys(spacelift_stack.default))}"
  }

  # Verify that project_root paths don't contain .terraform
  assert {
    condition = alltrue([
      for stack in values(spacelift_stack.default) :
      !can(regex("\\.terraform", stack.project_root))
    ])
    error_message = "Project root paths should not contain .terraform: ${jsonencode([for stack in values(spacelift_stack.default) : stack.project_root])}"
  }
}

# Test nested directory root module discovery
run "test_nested_directory_root_module_discovery" {
  command = plan

  variables {
    root_modules_path        = "./tests/fixtures/nested-multi-instance"
    all_root_modules_enabled = true
  }

  # Test that the nested root module path is correctly identified
  assert {
    condition     = contains(local._all_root_modules, "parent/nested")
    error_message = "Nested root module not discovered: ${jsonencode(local._all_root_modules)}"
  }

  # Test that only the expected root modules are found
  assert {
    condition     = length(local._all_root_modules) == 1
    error_message = "Expected exactly 1 nested root module, found: ${jsonencode(local._all_root_modules)}"
  }
}

# Test deeply nested directory support (3+ levels)
run "test_deeply_nested_directory_support" {
  command = plan

  # Create a temporary fixture for deeply nested structure
  variables {
    root_modules_path        = "./tests/fixtures"
    all_root_modules_enabled = true
    enabled_root_modules     = ["nested-multi-instance/parent/nested"]
  }

  # Test that deeply nested paths work correctly
  assert {
    condition     = contains(keys(spacelift_stack.default), "nested-multi-instance/parent/nested-dev")
    error_message = "Deeply nested directory dev stack not found: ${jsonencode(keys(spacelift_stack.default))}"
  }

  # Test project_root for deeply nested structure
  assert {
    condition     = spacelift_stack.default["nested-multi-instance/parent/nested-dev"].project_root == "./tests/fixtures/nested-multi-instance/parent/nested"
    error_message = "Deeply nested project_root incorrect: ${spacelift_stack.default["nested-multi-instance/parent/nested-dev"].project_root}"
  }

  # Test folder labels for deeply nested structure
  assert {
    condition     = contains(spacelift_stack.default["nested-multi-instance/parent/nested-dev"].labels, "folder:nested-multi-instance/parent/nested/dev")
    error_message = "Deeply nested folder label incorrect: ${jsonencode(spacelift_stack.default["nested-multi-instance/parent/nested-dev"].labels)}"
  }
}