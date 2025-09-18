variables {
  root_modules_path        = "./tests/fixtures/multi-instance"
  common_config_file       = "common.yaml"
  repository               = "terraform-spacelift-automation"
  all_root_modules_enabled = true
  aws_integration_enabled  = false
}

# Test github_enterprise dynamic block is created correctly
run "test_github_enterprise_integration" {
  command = plan

  variables {
    github_enterprise = {
      namespace = "masterpointio"
      id        = "test-gh-enterprise-id"
    }
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].github_enterprise[0].namespace == "masterpointio"
    error_message = "GitHub Enterprise namespace was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].github_enterprise)}"
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].github_enterprise[0].id == "test-gh-enterprise-id"
    error_message = "GitHub Enterprise id was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].github_enterprise)}"
  }
}

# Test raw_git dynamic block is created correctly
run "test_raw_git_integration" {
  command = plan

  variables {
    raw_git = {
      namespace = "my-git-namespace"
      url       = "https://git.example.com/repo.git"
    }
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].raw_git[0].namespace == "my-git-namespace"
    error_message = "Raw Git namespace was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].raw_git)}"
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].raw_git[0].url == "https://git.example.com/repo.git"
    error_message = "Raw Git url was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].raw_git)}"
  }
}

# Test that VCS blocks are empty when variables are null
run "test_vcs_blocks_empty_when_null" {
  command = plan

  variables {
    github_enterprise = null
    raw_git          = null
  }

  assert {
    condition     = length(spacelift_stack.default["root-module-a-test"].github_enterprise) == 0
    error_message = "GitHub Enterprise block should be empty when variable is null: ${jsonencode(spacelift_stack.default["root-module-a-test"].github_enterprise)}"
  }

  assert {
    condition     = length(spacelift_stack.default["root-module-a-test"].raw_git) == 0
    error_message = "Raw Git block should be empty when variable is null: ${jsonencode(spacelift_stack.default["root-module-a-test"].raw_git)}"
  }
}