# This test file validates the resource_id_resolver logic in main.tf which handles
# name-to-ID resolution for Spacelift resources and when to use global vs stack-level values,
# including Spaces, Worker Pools, and AWS Integrations, etc.

mock_provider "spacelift" {
  mock_data "spacelift_spaces" {
    defaults = {
      spaces = [
        {
          space_id    = "example-space-id"
          name        = "example-space"
          parent_space_id = "root"
          description = "Test space"
          labels      = []
          inherit_entities = true
        }
      ]
    }
  }

  mock_data "spacelift_worker_pools" {
    defaults = {
      worker_pools = [
        {
          worker_pool_id           = "example-worker-pool-id"
          name                     = "example-worker-pool"
          description              = "Test worker pool"
          labels                   = []
          config                   = ""
          space_id                 = "root"
          drift_detection_run_limit = 0
        }
      ]
    }
  }

  mock_data "spacelift_aws_integrations" {
    defaults = {
      integrations = [
        {
          integration_id                 = "example-aws-integration-id"
          name                           = "example-aws-integration"
          role_arn                       = "arn:aws:iam::123456789012:role/spacelift"
          external_id                    = "test"
          duration_seconds               = 3600
          generate_credentials_in_worker = false
          space_id                       = "root"
          labels                         = []
          region                         = "us-east-1"
          autoattach_enabled             = false
          tag_assume_role                = false
        }
      ]
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
    condition     = local.resource_id_resolver.space["root-module-a-default-example"] == "example-space-id"
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
    condition     = local.resource_id_resolver.worker_pool["root-module-a-test"] == "example-worker-pool-id"
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
    condition     = local.resource_id_resolver.worker_pool["root-module-a-test"] == "example-worker-pool-id"
    error_message = "Worker pool name from stack settings not taking precedence over global variable worker_pool_name: ${jsonencode(local.resource_id_resolver.worker_pool)}"
  }
}

########################################################
### AWS Integration ID Resolution Tests ###
########################################################

# Test AWS integration name-to-ID resolution via API lookup.
# Both the read and write resolvers fall back through the generic aws_integration_name,
# so a stack-level aws_integration_name populates both sides.
run "test_aws_integration_name_resolves_to_correct_id" {
  command = plan

  assert {
    condition     = local._aws_integration_read_ids["root-module-a-test"] == "example-aws-integration-id"
    error_message = "AWS integration name not resolving to correct read ID: ${jsonencode(local._aws_integration_read_ids)}"
  }

  assert {
    condition     = local._aws_integration_write_ids["root-module-a-test"] == "example-aws-integration-id"
    error_message = "AWS integration name not resolving to correct write ID: ${jsonencode(local._aws_integration_write_ids)}"
  }
}

# Test that stack-level aws_integration_name takes precedence over module-level aws_integration_name
run "test_aws_integration_name_takes_precedence_over_global_variable" {
  command = plan

  variables {
    aws_integration_name = "some-other-aws-integration"
  }

  assert {
    condition     = local._aws_integration_read_ids["root-module-a-test"] == "example-aws-integration-id"
    error_message = "Stack-level aws_integration_name not taking precedence over module-level for read: ${jsonencode(local._aws_integration_read_ids)}"
  }

  assert {
    condition     = local._aws_integration_write_ids["root-module-a-test"] == "example-aws-integration-id"
    error_message = "Stack-level aws_integration_name not taking precedence over module-level for write: ${jsonencode(local._aws_integration_write_ids)}"
  }
}

# Test that stack-level generic aws_integration_id takes precedence over module-level per-side IDs.
# Fallback chain: stack-level specific > stack-level generic > module-level specific > module-level generic.
run "test_stack_generic_id_beats_module_per_side" {
  command = plan

  variables {
    aws_integration_read_id  = "module-level-read"
    aws_integration_write_id = "module-level-write"
  }

  # default-example fixture sets stack-level aws_integration_id = "1234567890".
  assert {
    condition     = local._aws_integration_read_ids["root-module-a-default-example"] == "1234567890"
    error_message = "Stack-level aws_integration_id should win over module-level per-side read id: ${jsonencode(local._aws_integration_read_ids)}"
  }

  assert {
    condition     = local._aws_integration_write_ids["root-module-a-default-example"] == "1234567890"
    error_message = "Stack-level aws_integration_id should win over module-level per-side write id: ${jsonencode(local._aws_integration_write_ids)}"
  }
}

########################################################
### AWS Integration shape validation checks ###
########################################################

# Setting only one side (read without write) must trigger aws_integration_per_side_must_be_paired.
run "test_read_without_write_fails_paired_check" {
  command = plan

  expect_failures = [check.aws_integration_per_side_must_be_paired]

  variables {
    aws_integration_read_id = "read-only-integration"
    # aws_integration_write_id intentionally omitted
  }
}

# Setting only one side (write without read) must trigger aws_integration_per_side_must_be_paired.
run "test_write_without_read_fails_paired_check" {
  command = plan

  expect_failures = [check.aws_integration_per_side_must_be_paired]

  variables {
    aws_integration_write_id = "write-only-integration"
    # aws_integration_read_id intentionally omitted
  }
}

# Mixing generic and per-side vars must trigger aws_integration_single_vs_split_exclusivity.
run "test_generic_and_per_side_together_fails_exclusivity_check" {
  command = plan

  expect_failures = [check.aws_integration_single_vs_split_exclusivity]

  variables {
    aws_integration_id       = "generic-integration"
    aws_integration_read_id  = "read-integration"
    aws_integration_write_id = "write-integration"
  }
}


