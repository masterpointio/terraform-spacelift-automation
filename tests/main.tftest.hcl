variables {
  root_modules_path  = "./tests/fixtures/multi-instance"
  common_config_file = "common.yaml"
  github_enterprise = {
    namespace = "masterpointio"
  }
  repository               = "terraform-spacelift-automation"
  all_root_modules_enabled = true
  aws_integration_enabled  = false
  before_init = [
    "echo 'Hello'"
  ]
  labels = [
    "nobackend"
  ]
}

#Test that the global labels are created correctly
run "test_labels_are_created_correctly" {
  command = plan

  assert {
    condition     = contains(local.labels["root-module-a-test"], "nobackend")
    error_message = "Global labels were not created correctly: ${jsonencode(local.labels)}"
  }
}

# Test that the root module fileset is created correctly
run "test_root_module_fileset_collects_all_root_modules" {
  command = plan

  assert {
    condition     = contains(local._all_root_modules, "root-module-a")
    error_message = "Root module fileset was not created correctly: ${jsonencode(local._all_root_modules)}"
  }
}

# Test that the configs are created correctly and common labels are merged
run "test_common_labels_are_appended_to_stack_labels" {
  command = plan

  assert {
    condition     = contains(local.configs["root-module-a-test"].stack_settings.labels, "common_label") && contains(local.configs["root-module-a-test"].stack_settings.labels, "test_label")
    error_message = "Common labels were not merged correctly: ${jsonencode(local.configs)}"
  }
}

# Test that the stack names are created correctly
run "test_stacks_include_expected" {
  command = plan

  assert {
    condition     = contains(local.stacks, "root-module-a-test")
    error_message = "Stack names were not created correctly: ${jsonencode(local.stacks)}"
  }
}

# Test that the stack resource is created with the correct name
run "test_stack_resource_is_created_with_correct_name" {
  command = plan

  assert {
    condition = spacelift_stack.default["root-module-a-test"].name == "root-module-a-test"
    error_message = "Stack resource was not created correctly: ${jsonencode(spacelift_stack.default)}"
  }
}

# Test that the folder labels get created with correct format
run "test_folder_labels_are_correct_format" {
  command = plan

  assert {
    condition     = contains(local._folder_labels["root-module-a-test"], "folder:root-module-a/test")
    error_message = "Folder label was not created correctly for root-module-a: ${jsonencode(local._folder_labels)}"
  }
}

# Test terraform_workspace is set to stack file name when default_tf_workspace_enabled is false (the default)
run "test_workspace_when_default_tf_workspace_enabled_is_false" {
  command = plan

  assert {
    condition     = local.configs["root-module-a-test"].terraform_workspace == "test"
    error_message = "Terraform workspace was not set correctly when default_tf_workspace_enabled is false: ${jsonencode(local.configs)}"
  }
}

# Test that the default_tf_workspace_enabled is used correctly
run "test_workspace_when_default_tf_workspace_enabled" {
  command = plan

  assert {
    condition     = local.configs["root-module-a-default-example"].terraform_workspace == "default"
    error_message = "Default Terraform workspace was not used correctly: ${jsonencode(local.configs)}"
  }
}

# Test that the administrative label is added to the stack when the stack is set to administrative
run "test_administrative_label_is_added_to_stack" {
  command = plan

  assert {
    condition     = contains(local.labels["root-module-a-default-example"], "administrative")
    error_message = "Administrative label was not added to the stack: ${jsonencode(local.labels)}"
  }
}

# Test that the administrative label is not added to the stack when the stack is not set to administrative
run "test_administrative_label_is_not_added_to_stack_when_not_administrative" {
  command = plan

  assert {
    condition     = !contains(local.labels["root-module-a-test"], "administrative")
    error_message = "Administrative label was added to the stack when it should not have been: ${jsonencode(local.labels)}"
  }
}

# Test that the depends-on label is added to the stack
run "test_depends_on_label_is_added_to_stack" {
  command = plan

  assert {
    condition     = contains(local.labels["root-module-a-test"], "depends-on:spacelift-automation-default")
    error_message = "Depends-on label was not added to the stack: ${jsonencode(local.labels)}"
  }
}

# Test before_init excludes the expected tfvars copy command when tfvars are not enabled
run "test_before_init_excludes_the_expected_tfvars_copy_command_when_tfvars_are_not_enabled" {
  command = plan

  assert {
    condition     = !contains(local.before_init["root-module-a-default-example"], "cp tfvars/default-example.tfvars spacelift.auto.tfvars")
    error_message = "Before_init was not created correctly: ${jsonencode(local.before_init)}"
  }
}

# Test before_init includes the expected tfvars copy command
run "test_before_init_includes_the_expected_tfvars_copy_command" {
  command = plan

  assert {
    condition     = contains(local.before_init["root-module-a-test"], "cp tfvars/test.tfvars spacelift.auto.tfvars")
    error_message = "Before_init was not created correctly: ${jsonencode(local.before_init)}"
  }
}

# Test before_init includes the include the default before_init and stack before_init
run "test_before_init_includes_the_default_before_init_and_stack_before_init" {
  command = plan

  assert {
    condition     = contains(local.before_init["root-module-a-default-example"], "echo 'Hello'") && contains(local.before_init["root-module-a-default-example"], "echo 'World'")
    error_message = "Before_init was not created correctly: ${jsonencode(local.before_init)}"
  }
}

# Test that the description is created correctly
run "test_description_is_created_correctly" {
  command = plan

  assert {
    condition = spacelift_stack.default["root-module-a-test"].description == "Root Module: root-module-a\nProject Root: ./tests/fixtures/multi-instance/root-module-a\nWorkspace: test\nManaged by spacelift-automation Terraform root module."
    error_message = "Description was not created correctly: ${jsonencode(local.configs)}"
  }
}

# Test that the description is created correctly when non-default template string is used
run "test_description_is_created_correctly_when_non_default_template_string_is_used" {
  command = plan
  variables {
    description = "Space ID: $${stack_settings.space_id}"
  }

  assert {
    condition = spacelift_stack.default["root-module-a-test"].description == "Space ID: 123"
    error_message = "Description was not created correctly: ${jsonencode(local.configs)}"
  }
}

run "test_description_is_created_correctly_when_passed_from_stack_config" {
  command = plan

  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].description == "This is a test of the emergency broadcast system"
    error_message = "Description was not created correctly: ${jsonencode(local.configs)}"
  }
}


# Test that space_name from stack settings resolves to correct ID
run "test_space_name_resolves_to_correct_id" {
  command = plan

  assert {
    condition     = local.resolved_space_ids["root-module-a-default-example"] == "mp-automation-01JEC2D4K2Q2V1AJQ0Y6BFGJJ3" # For the `masterpointio.app.spacelift.io`
    error_message = "Space name not resolving to correct ID: ${jsonencode(local.resolved_space_ids)}"
  }
}

# Test that space_id from stack settings takes precedence over space_id global variable
run "test_space_id_takes_precedence_over_space_id_global_variable" {
  command = plan

  variables {
    space_id = "default-space-id-global"
  }

  assert {
    condition     = local.resolved_space_ids["root-module-a-test"] == "direct-space-id-stack-yaml"
    error_message = "Space ID from stack settings not taking precedence over global variable space ID: ${jsonencode(local.resolved_space_ids)}"
  }
}
