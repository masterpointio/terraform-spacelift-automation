# Tests for the project_root_prefix variable.
#
# Background: spacelift-automation needs two paths to behave correctly:
#   - root_modules_discovery_path → relative to path.root, used by fileset() for discovery.
#   - project_root_prefix         → relative to the repo root, used to set each stack's
#                                   Spacelift project_root.
#
# When project_root_prefix is null, the discovery path is used verbatim — only valid when
# the discovery path is already repo-root-relative (no "../" segments). The variable
# validation rejects the ambiguous case at plan time.

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
  workspace_prefix_enabled = false
  repository               = "terraform-spacelift-automation"
  github_enterprise = {
    namespace = "masterpointio"
  }
  aws_integration_enabled = false
}

# Default behavior without project_root_prefix: discovery path is used verbatim.
# This is only valid because the discovery path here has no "../" segments.
run "test_project_root_without_prefix_uses_discovery_path_verbatim" {
  command = plan

  variables {
    root_modules_discovery_path = "./tests/fixtures/multi-instance"
    all_root_modules_enabled    = true
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].project_root == "./tests/fixtures/multi-instance/root-module-a"
    error_message = "Without project_root_prefix the discovery path must be used verbatim: ${spacelift_stack.default["root-module-a-test"].project_root}"
  }
}

# Main use case: discovery path is module-relative ("../"), project_root_prefix is the
# repo-root-relative path Spacelift should record on each stack.
run "test_project_root_with_prefix" {
  command = plan

  variables {
    root_modules_discovery_path = "./tests/fixtures/multi-instance"
    project_root_prefix         = "terraform/root-modules"
    all_root_modules_enabled    = true
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].project_root == "terraform/root-modules/root-module-a"
    error_message = "project_root with prefix should equal '<prefix>/<module>': ${spacelift_stack.default["root-module-a-test"].project_root}"
  }
}

# project_root_prefix preserves the nested module path (parent/nested → prefix/parent/nested).
run "test_project_root_prefix_with_nested_directories" {
  command = plan

  variables {
    root_modules_discovery_path = "./tests/fixtures/nested-multi-instance"
    project_root_prefix         = "infra/terraform/modules"
    root_module_structure       = "MultiInstance"
    all_root_modules_enabled    = true
  }

  assert {
    condition     = spacelift_stack.default["parent/nested-dev"].project_root == "infra/terraform/modules/parent/nested"
    error_message = "Nested project_root with prefix incorrect: ${spacelift_stack.default["parent/nested-dev"].project_root}"
  }
}

# Per-stack `stack_settings.project_root` in YAML always wins, even when prefix is set.
run "test_stack_project_root_takes_precedence_over_prefix" {
  command = plan

  variables {
    root_modules_discovery_path = "./tests/fixtures/multi-instance"
    project_root_prefix         = "should/be/ignored"
    all_root_modules_enabled    = true
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-custom-project-root"].project_root == "custom/path/to/root-module-a"
    error_message = "Per-stack project_root should win over prefix: ${spacelift_stack.default["root-module-a-custom-project-root"].project_root}"
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].project_root == "should/be/ignored/root-module-a"
    error_message = "Stack without per-stack project_root should use prefix: ${spacelift_stack.default["root-module-a-test"].project_root}"
  }
}

# project_root_prefix works the same way under SingleInstance.
run "test_project_root_prefix_with_single_instance" {
  command = plan

  variables {
    root_module_structure       = "SingleInstance"
    root_modules_discovery_path = "./tests/fixtures/single-instance"
    project_root_prefix         = "terraform/single"
    all_root_modules_enabled    = true
  }

  assert {
    condition     = spacelift_stack.default["root-module-a"].project_root == "terraform/single/root-module-a"
    error_message = "SingleInstance project_root with prefix incorrect: ${spacelift_stack.default["root-module-a"].project_root}"
  }
}
