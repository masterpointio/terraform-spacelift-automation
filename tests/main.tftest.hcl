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
run "test_root_module_fileset" {
  command = plan

  assert {
    condition = contains(local._all_root_modules, "root-module-a")
    error_message = "Root module fileset was not created correctly: ${jsonencode(local._all_root_modules)}"
  }
}

# Test that the configs are created correctly and common labels are merged
run "test_configs" {
  command = plan

  assert {
    condition = contains(local.configs["root-module-a-test"].stack_settings.labels, "common_label") && contains(local.configs["root-module-a-test"].stack_settings.labels, "test_label")
    error_message = "Common labels were not merged correctly: ${jsonencode(local.configs)}"
  }
}

# Test that the stack names are created correctly
run "test_stacks" {
  command = plan

  assert {
    condition = contains(local.stacks, "root-module-a-test")
    error_message = "Stack names were not created correctly: ${jsonencode(local.stacks)}"
  }
}

# Test that the folder labels get created with correct format
run "test_folder_labels" {
  command = plan

  assert {
    condition = contains(local._folder_labels["root-module-a-test"], "folder:root-module-a/test")
    error_message = "Folder label was not created correctly for root-module-a: ${jsonencode(local._folder_labels)}"
  }
}
