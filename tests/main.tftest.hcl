variables {
  root_modules_path = "./tests/fixtures"
  common_config_file = "common.yaml"
  github_enterprise = {
    namespace = "masterpointio"
  }
  repository = "terraform-spacelift-automation"
  all_root_modules_enabled = true
  aws_integration_enabled = false
}

# Test that the root module fileset is created correctly
run "test_root_module_fileset_collects_all_root_modules" {
  command = plan

  assert {
    condition = contains(local._all_root_modules, "root-module-a")
    error_message = "Root module fileset was not created correctly: ${jsonencode(local._all_root_modules)}"
  }
}

# Test that the configs are created correctly and common labels are merged
run "test_common_labels_are_appended_to_stack_labels" {
  command = plan

  assert {
    condition = contains(local.configs["root-module-a-test"].stack_settings.labels, "common_label") && contains(local.configs["root-module-a-test"].stack_settings.labels, "test_label")
    error_message = "Common labels were not merged correctly: ${jsonencode(local.configs)}"
  }
}

# Test that the stack names are created correctly
run "test_stacks_include_expected" {
  command = plan

  assert {
    condition = contains(local.stacks, "root-module-a-test")
    error_message = "Stack names were not created correctly: ${jsonencode(local.stacks)}"
  }
}

# Test that the folder labels get created with correct format
run "test_folder_labels_are_correct_format" {
  command = plan

  assert {
    condition = contains(local._folder_labels["root-module-a-test"], "folder:root-module-a/test")
    error_message = "Folder label was not created correctly for root-module-a: ${jsonencode(local._folder_labels)}"
  }
}

# Test terraform_workspace is set to stack file name when default_tf_workspace_enabled is false (the default)
run "test_workspace_when_default_tf_workspace_enabled_is_false" {
  command = plan

  assert {
    condition = local.configs["root-module-a-test"].terraform_workspace == "test"
    error_message = "Terraform workspace was not set correctly when default_tf_workspace_enabled is false: ${jsonencode(local.configs)}"
  }
}

# Test that the default_tf_workspace_enabled is used correctly
run "test_workspace_when_default_tf_workspace_enabled" {
  command = plan

  assert {
    condition = local.configs["root-module-a-default-example"].terraform_workspace == "default"
    error_message = "Default Terraform workspace was not used correctly: ${jsonencode(local.configs)}"
  }
}
