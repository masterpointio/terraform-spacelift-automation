variables {
  root_modules_path = "./tests/fixtures/multi-instance"
  common_config_file = "common.yaml"
  github_enterprise = {
    namespace = "masterpointio"
  }
  repository = "terraform-spacelift-automation"
  all_root_modules_enabled = true
  aws_integration_enabled = false
  before_init = [
    "echo 'Hello'"
  ]
  labels = [
    "nobackend"
  ]
}

# Test the default-example stack results in all the right final resource values
# We don't test labels here because we test them below.
run "test_default_example_stack_final_values" {
  command = plan

  # administrative
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].administrative == true
    error_message = "Administrative was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # additional_project_globs
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].additional_project_globs, "glob/*")
    error_message = "additional_project_globs was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_apply
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_apply, "echo 'after_apply'")
    error_message = "after_apply was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_destroy
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_destroy, "echo 'after_destroy'")
    error_message = "after_destroy was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_init
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_init, "echo 'after_init'")
    error_message = "after_init was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_perform
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_perform, "echo 'after_perform'")
    error_message = "after_perform was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_plan
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_plan, "echo 'after_plan'")
    error_message = "after_plan was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # autodeploy
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].autodeploy == false
    error_message = "autodeploy was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # autoretry
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].autoretry == true
    error_message = "autoretry was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_apply
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_apply, "echo 'before_apply'")
    error_message = "before_apply was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_destroy
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_destroy, "echo 'before_destroy'")
    error_message = "before_destroy was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_init
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_init, "echo 'before_init'")
    error_message = "before_init was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_perform
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_perform, "echo 'before_perform'")
    error_message = "before_perform was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_plan
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_plan, "echo 'before_plan'")
    error_message = "before_plan was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # branch
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].branch == "prod"
    error_message = "branch was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # description
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].description == "This is a test of the emergency broadcast system"
    error_message = "description was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # enable_local_preview
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].enable_local_preview == true
    error_message = "enable_local_preview was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # enable_well_known_secret_masking
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].enable_well_known_secret_masking == false
    error_message = "enable_well_known_secret_masking was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # github_action_deploy
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].github_action_deploy == false
    error_message = "github_action_deploy was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # manage_state
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].manage_state == true
    error_message = "manage_state was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # protect_from_deletion
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].protect_from_deletion == true
    error_message = "protect_from_deletion was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # runner_image
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].runner_image == "masterpointio/spacelift-runner:latest"
    error_message = "runner_image was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # space_id
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].space_id == "1234567890"
    error_message = "space_id was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # terraform_smart_sanitization
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].terraform_smart_sanitization == true
    error_message = "terraform_smart_sanitization was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # terraform_version
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].terraform_version == "1.9.0"
    error_message = "Terraform version was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # worker_pool_id
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].worker_pool_id == "1234567890"
    error_message = "worker_pool_id was not correct on the default-example stack: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # destructor_enabled
  assert {
    condition = spacelift_stack_destructor.default["root-module-a-default-example"].deactivated == false
    error_message = "destructor_enabled was not correct on the default-example stack: ${jsonencode(spacelift_stack_destructor.default["root-module-a-default-example"])}"
  }

  # aws_integration_id
  assert {
    condition = spacelift_aws_integration_attachment.default["root-module-a-default-example"].integration_id == "1234567890"
    error_message = "aws_integration_id was not correct on the default-example stack: ${jsonencode(spacelift_aws_integration_attachment.default["root-module-a-default-example"])}"
  }

  # drift_detection_ignore_state
  assert {
    condition = spacelift_drift_detection.default["root-module-a-default-example"].ignore_state == true
    error_message = "drift_detection_ignore_state was not correct on the default-example stack: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }

  # drift_detection_reconcile
  assert {
    condition = spacelift_drift_detection.default["root-module-a-default-example"].reconcile == true
    error_message = "drift_detection_reconcile was not correct on the default-example stack: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }

  # drift_detection_schedule
  assert {
    condition = contains(spacelift_drift_detection.default["root-module-a-default-example"].schedule, "0 0 * * *")
    error_message = "drift_detection_schedule was not correct on the default-example stack: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }

  # drift_detection_timezone
  assert {
    condition = spacelift_drift_detection.default["root-module-a-default-example"].timezone == "America/Denver"
    error_message = "drift_detection_timezone was not correct on the default-example stack: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }
}

# Test the default-example stack with runtime overrides
run "test_default_example_stack_runtime_overrides" {
  command = plan

  variables {
    runtime_overrides = {
      root-module-a = {
        stack_settings = {
          administrator = false
          additional_project_globs = ["changed/*"]
          after_apply = ["echo 'changed_after_apply'"]
          after_destroy = ["echo 'changed_after_destroy'"]
          after_init = ["echo 'changed_after_init'"]
          after_perform = ["echo 'changed_after_perform'"]
          after_plan = ["echo 'changed_after_plan'"]
          autodeploy = true
          autoretry = false
          before_apply = ["echo 'changed_before_apply'"]
          before_destroy = ["echo 'changed_before_destroy'"]
          before_init = ["echo 'changed_before_init'"]
          before_perform = ["echo 'changed_before_perform'"]
          before_plan = ["echo 'changed_before_plan'"]
          branch = "dev"
          description = "This is a changed test of the emergency broadcast system"
          enable_local_preview = false
          enable_well_known_secret_masking = true
          github_action_deploy = true
          manage_state = false
          protect_from_deletion = false
          runner_image = "masterpointio/spacelift-runner:dev"
          space_id = "555"
          terraform_smart_sanitization = false
          terraform_version = "1.9.1"
          worker_pool_id = "555"

          destructor_enabled = false

          aws_integration_enabled = true
          aws_integration_id = "999"

          drift_detection_enabled = true
          drift_detection_ignore_state = false
          drift_detection_reconcile = false
          drift_detection_schedule = ["0 7 * * *"]
          drift_detection_timezone = "America/Denver"
        }
      }
    }
  }

  # administrative
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].administrative == false
    error_message = "Administrative override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # additional_project_globs
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].additional_project_globs, "changed/*")
    error_message = "additional_project_globs override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_apply
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_apply, "echo 'changed_after_apply'")
    error_message = "after_apply override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_destroy
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_destroy, "echo 'changed_after_destroy'")
    error_message = "after_destroy override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_init
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_init, "echo 'changed_after_init'")
    error_message = "after_init override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_perform
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_perform, "echo 'changed_after_perform'")
    error_message = "after_perform override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # after_plan
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].after_plan, "echo 'changed_after_plan'")
    error_message = "after_plan override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # autodeploy
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].autodeploy == true
    error_message = "autodeploy override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # autoretry
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].autoretry == false
    error_message = "autoretry override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_apply
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_apply, "echo 'changed_before_apply'")
    error_message = "before_apply override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_destroy
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_destroy, "echo 'changed_before_destroy'")
    error_message = "before_destroy override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_init
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_init, "echo 'changed_before_init'")
    error_message = "before_init override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_perform
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_perform, "echo 'changed_before_perform'")
    error_message = "before_perform override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # before_plan
  assert {
    condition = contains(spacelift_stack.default["root-module-a-default-example"].before_plan, "echo 'changed_before_plan'")
    error_message = "before_plan override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # branch
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].branch == "dev"
    error_message = "branch override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # description
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].description == "This is a changed test of the emergency broadcast system"
    error_message = "description override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # enable_local_preview
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].enable_local_preview == false
    error_message = "enable_local_preview override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # enable_well_known_secret_masking
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].enable_well_known_secret_masking == true
    error_message = "enable_well_known_secret_masking override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # github_action_deploy
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].github_action_deploy == true
    error_message = "github_action_deploy override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # manage_state
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].manage_state == false
    error_message = "manage_state override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # protect_from_deletion
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].protect_from_deletion == false
    error_message = "protect_from_deletion override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # runner_image
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].runner_image == "masterpointio/spacelift-runner:dev"
    error_message = "runner_image override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # space_id
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].space_id == "555"
    error_message = "space_id override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # terraform_smart_sanitization
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].terraform_smart_sanitization == false
    error_message = "terraform_smart_sanitization override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # terraform_version
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].terraform_version == "1.9.1"
    error_message = "terraform_version override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # worker_pool_id
  assert {
    condition = spacelift_stack.default["root-module-a-default-example"].worker_pool_id == "555"
    error_message = "worker_pool_id override was not applied correctly: ${jsonencode(spacelift_stack.default["root-module-a-default-example"])}"
  }

  # destructor_enabled
  assert {
    condition = spacelift_stack_destructor.default["root-module-a-default-example"].deactivated == true
    error_message = "destructor_enabled override was not applied correctly: ${jsonencode(spacelift_stack_destructor.default["root-module-a-default-example"])}"
  }

  # aws_integration_id
  assert {
    condition = spacelift_aws_integration_attachment.default["root-module-a-default-example"].integration_id == "999"
    error_message = "aws_integration_id override was not applied correctly: ${jsonencode(spacelift_aws_integration_attachment.default["root-module-a-default-example"])}"
  }

  # drift_detection_ignore_state
  assert {
    condition = spacelift_drift_detection.default["root-module-a-default-example"].ignore_state == false
    error_message = "drift_detection_ignore_state override was not applied correctly: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }

  # drift_detection_reconcile
  assert {
    condition = spacelift_drift_detection.default["root-module-a-default-example"].reconcile == false
    error_message = "drift_detection_reconcile override was not applied correctly: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }

  # drift_detection_schedule
  assert {
    condition = contains(spacelift_drift_detection.default["root-module-a-default-example"].schedule, "0 7 * * *")
    error_message = "drift_detection_schedule override was not applied correctly: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }

  # drift_detection_timezone
  assert {
    condition = spacelift_drift_detection.default["root-module-a-default-example"].timezone == "America/Denver"
    error_message = "drift_detection_timezone override was not applied correctly: ${jsonencode(spacelift_drift_detection.default["root-module-a-default-example"])}"
  }
}

# Test that the global labels are created correctly
run "test_labels_are_created_correctly" {
  command = plan

  assert {
    condition = contains(local.labels["root-module-a-test"], "nobackend")
    error_message = "Global labels were not created correctly: ${jsonencode(local.labels)}"
  }
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

# Test that the administrative label is added to the stack when the stack is set to administrative
run "test_administrative_label_is_added_to_stack" {
  command = plan

  assert {
    condition = contains(local.labels["root-module-a-default-example"], "administrative")
    error_message = "Administrative label was not added to the stack: ${jsonencode(local.labels)}"
  }
}

# Test that the administrative label is not added to the stack when the stack is not set to administrative
run "test_administrative_label_is_not_added_to_stack_when_not_administrative" {
  command = plan

  assert {
    condition = !contains(local.labels["root-module-a-test"], "administrative")
    error_message = "Administrative label was added to the stack when it should not have been: ${jsonencode(local.labels)}"
  }
}

# Test that the depends-on label is added to the stack
run "test_depends_on_label_is_added_to_stack" {
  command = plan

  assert {
    condition = contains(local.labels["root-module-a-test"], "depends-on:spacelift-automation-default")
    error_message = "Depends-on label was not added to the stack: ${jsonencode(local.labels)}"
  }
}

# Test before_init excludes the expected tfvars copy command when tfvars are not enabled
run "test_before_init_excludes_the_expected_tfvars_copy_command_when_tfvars_are_not_enabled" {
  command = plan

  assert {
    condition = !contains(local.before_init["root-module-a-default-example"], "cp tfvars/default-example.tfvars spacelift.auto.tfvars")
    error_message = "Before_init was not created correctly: ${jsonencode(local.before_init)}"
  }
}

# Test before_init includes the expected tfvars copy command
run "test_before_init_includes_the_expected_tfvars_copy_command" {
  command = plan

  assert {
    condition = contains(local.before_init["root-module-a-test"], "cp tfvars/test.tfvars spacelift.auto.tfvars")
    error_message = "Before_init was not created correctly: ${jsonencode(local.before_init)}"
  }
}

# Test before_init includes the include the default before_init and stack before_init
run "test_before_init_includes_the_default_before_init_and_stack_before_init" {
  command = plan

  assert {
    condition = contains(local.before_init["root-module-a-default-example"], "echo 'Hello'") && contains(local.before_init["root-module-a-default-example"], "echo 'before_init'")
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
