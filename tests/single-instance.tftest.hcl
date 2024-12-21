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
