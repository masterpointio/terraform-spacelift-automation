# This test file validates the resource_id_resolver logic in main.tf which handles
# name-to-ID resolution for Spacelift resources and when to use global vs stack-level values,
# including Spaces, Worker Pools, and AWS Integrations, etc.
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

########################################################
### Space ID Resolution Tests ###
########################################################
run "test_space_name_is_used" {
  command = plan

  assert {
    condition     = local.resource_id_resolver.space["root-module-a-default-example"] == "mp-aws-automation-01JK7A21DW1YH3Q64JHS3RYNP9"
    error_message = "Space name not being used: ${jsonencode(local.resource_id_resolver.space)}"
  }
}

# Test that direct stack-level space_id takes precedence over global space_id variable
run "test_space_id_takes_precedence_over_global_variable" {
  command = plan

  variables {
    space_id = "default-space-id-global"
  }

  assert {
    condition     = local.resource_id_resolver.space["root-module-a-test"] == "direct-space-id-stack-yaml"
    error_message = "Space ID from stack settings not taking precedence over global variable space ID: ${jsonencode(local.resource_id_resolver.space)}"
  }
}

run "test_global_space_id_variable_is_used" {
  command = plan

  variables {
    space_id = "global-space-id-from-variable"
    root_modules_path = "./tests/fixtures/single-instance"
    root_module_structure = "SingleInstance"
  }

  assert {
    condition     = local.resource_id_resolver.space["root-module-a"] == "global-space-id-from-variable"
    error_message = "Global space_id variable not being used when no stack-level values provided: ${jsonencode(local.resource_id_resolver.space)}"
  }
}

# Test that default space_id ("root") is used when no other values are provided
run "test_default_space_id_is_used_when_no_values_provided" {
  command = plan

  variables {
    root_modules_path = "./tests/fixtures/single-instance"
    root_module_structure = "SingleInstance"
  }

  assert {
    condition     = local.resource_id_resolver.space["root-module-a"] == "root"
    error_message = "Default space_id (root) was not used when no other values provided: ${jsonencode(local.resource_id_resolver.space)}"
  }
}

# Test that direct stack-level space_id from stack.yaml is used in SingleInstance mode
run "test_single_instance_space_id_from_stack_yaml" {
  command = plan

  variables {
    root_modules_path = "./tests/fixtures/single-instance"
    root_module_structure = "SingleInstance"
  }

  assert {
    condition     = local.resource_id_resolver.space["root-module-b"] == "some-space-id"
    error_message = "Space ID from stack.yaml is not being used: ${jsonencode(local.resource_id_resolver.space)}"
  }
}


########################################################
### Worker Pool ID Resolution Tests ###
########################################################

# Test worker pool name-to-ID resolution via API lookup
run "test_worker_pool_name_resolves_to_correct_id" {
  command = plan

  assert {
    condition     = local.resource_id_resolver.worker_pool["root-module-a-test"] == "01K3VABYB4FBXNV24KN4A4EKC8" # For the `mp-ue1-automation-spft-priv-workers` in our `mp-infra` Spacelift account
    error_message = "Worker pool name not resolving to correct ID: ${jsonencode(local.resource_id_resolver.worker_pool)}"
  }
}

# Test that stack-level worker_pool_name takes precedence over global worker_pool_name variable
run "test_worker_pool_name_takes_precedence_over_global_variable" {
  command = plan

  variables {
    worker_pool_name = "some-other-worker-pool"
  }

  assert {
    condition     = local.resource_id_resolver.worker_pool["root-module-a-test"] == "01K3VABYB4FBXNV24KN4A4EKC8" # For the `mp-ue1-automation-spft-priv-workers` in our `mp-infra` Spacelift account
    error_message = "Worker pool name from stack settings not taking precedence over global variable worker_pool_name: ${jsonencode(local.resource_id_resolver.worker_pool)}"
  }
}

########################################################
### AWS Integration ID Resolution Tests ###
########################################################

# Test AWS integration name-to-ID resolution via API lookup
run "test_aws_integration_name_resolves_to_correct_id" {
  command = plan

  assert {
    condition     = local.resource_id_resolver.aws_integration["root-module-a-test"] == "01JEC7ZACVKHTSVY4NF8QNZVVB" # For the `mp-automation-755965222190` in our `mp-infra` Spacelift account
    error_message = "AWS integration name not resolving to correct ID: ${jsonencode(local.resource_id_resolver.aws_integration)}"
  }
}

# Test that stack-level aws_integration_name takes precedence over global aws_integration_name variable
run "test_aws_integration_name_takes_precedence_over_global_variable" {
  command = plan

  variables {
    aws_integration_name = "some-other-aws-integration"
  }

  assert {
    condition     = local.resource_id_resolver.aws_integration["root-module-a-test"] == "01JEC7ZACVKHTSVY4NF8QNZVVB" # For the `mp-automation-755965222190` in our `mp-infra` Spacelift account
    error_message = "AWS integration name from stack settings not taking precedence over global variable aws_integration_name: ${jsonencode(local.resource_id_resolver.aws_integration)}"
  }
}
