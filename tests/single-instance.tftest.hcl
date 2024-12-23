provider "spacelift" {
  api_key_endpoint = "https://masterpointio.app.spacelift.io"
}

variables {
  root_modules_path = "./tests/fixtures/single-instance"
  github_enterprise = {
    namespace = "masterpointio"
  }
  repository = "terraform-spacelift-automation"
  all_root_modules_enabled = true
  aws_integration_enabled = false
  before_init = [
    "echo 'Hello'"
  ]

  root_module_structure = "SingleInstance"
}

# Test that the root module fileset is created correctly
run "test_single_instance_root_module_fileset_collects_all_root_modules" {
  command = plan

  assert {
    condition = contains(local._all_root_modules, "root-module-a")
    error_message = "Root module fileset was not created correctly: ${jsonencode(local._all_root_modules)}"
  }
}

# Test that the stack names are created correctly
run "test_single_instance_stacks_include_expected" {
  command = plan

  assert {
    condition = contains(local.stacks, "root-module-a")
    error_message = "Stack names were not created correctly: ${jsonencode(local.stacks)}"
  }
}

run "test_single_instance_stacks_only_include_default_stack" {
  command = plan

  assert {
    condition = length(local._root_module_yaml_decoded["root-module-a"]) == 1 && local._root_module_yaml_decoded["root-module-a"]["default"] != null
    error_message = "_root_module_yaml_decoded is not a single instance: ${jsonencode(local._root_module_yaml_decoded)}"
  }
}

run "test_single_instance_stack_configs_stack_name_is_correct" {
  command = plan

  assert {
    condition = length(local._root_module_stack_configs) == 1 && local._root_module_stack_configs["root-module-a"] != null
    error_message = "_root_module_stack_configs is not expected structure: ${jsonencode(local._root_module_stack_configs)}"
  }
}

run "test_single_instance_stack_configs_use_default_tf_workspace" {
  command = plan

  assert {
    condition = local._root_module_stack_configs["root-module-a"].terraform_workspace == "default"
    error_message = "terraform_workspace is not set to default: ${jsonencode(local._root_module_stack_configs)}"
  }
}

run "test_single_instance_stack_configs_project_root_is_correct" {
  command = plan

  assert {
    condition = local._root_module_stack_configs["root-module-a"].project_root == "${var.root_modules_path}/root-module-a"
    error_message = "project_root is not correct for root-module-a: ${jsonencode(local._root_module_stack_configs)}"
  }
}

# Test that the administrative label is not added to the stack when the stack is not set to administrative
run "test_single_instance_administrative_label_is_not_added_to_stack_when_not_administrative" {
  command = plan

  assert {
    condition = !contains(local.labels["root-module-a"], "administrative")
    error_message = "Administrative label was added to the stack when it should not have been: ${jsonencode(local.labels)}"
  }
}

# Test that the depends-on label is added to the stack
run "test_single_instance_depends_on_label_is_added_to_stack" {
  command = plan

  assert {
    condition = contains(local.labels["root-module-a"], "depends-on:spacelift-automation-default")
    error_message = "Depends-on label was not added to the stack: ${jsonencode(local.labels)}"
  }
}

# Test that the folder label is added to the stack and doesn't include a workspace name
run "test_single_instance_folder_label_is_added_to_stack_and_doesnt_include_workspace_name" {
  command = plan

  assert {
    condition = contains(local.labels["root-module-a"], "folder:root-module-a")
    error_message = "Folder label was not added to the stack: ${jsonencode(local.labels)}"
  }
}

# Test that stack.yaml labels are included in the stack labels
run "test_single_instance_stack_yaml_labels_are_included_in_stack_labels" {
  command = plan

  assert {
    condition = contains(local.labels["root-module-a"], "stack_label")
    error_message = "Stack.yaml labels were not included in the stack labels: ${jsonencode(local.labels)}"
  }
}

# Test that the before_init steps are added to the stack
run "test_single_instance_before_init_steps_are_added_to_stack" {
  command = plan

  assert {
    condition = contains(local.before_init["root-module-a"], "echo 'Hello'") && contains(local.before_init["root-module-a"], "echo 'World'")
    error_message = "Before_init steps were not added to the stack: ${jsonencode(local.before_init)}"
  }
}

# Test that the before_init tfvar cp command is not added to the stack
run "test_single_instance_before_init_tfvar_cp_command_is_not_added_to_stack" {
  command = plan

  assert {
    condition = !contains(local.before_init["root-module-a"], "cp tfvars/")
    error_message = "Before_init tfvar cp command was added to the stack: ${jsonencode(local.before_init)}"
  }
}
