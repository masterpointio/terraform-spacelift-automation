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
  root_modules_path        = "./tests/fixtures/multi-instance"
  common_config_file       = "common.yaml"
  repository               = "terraform-spacelift-automation"
  all_root_modules_enabled = true
  aws_integration_enabled  = false
}

# Test gitlab dynamic block is created correctly
run "test_gitlab_integration_id_is_null" {
  command = plan

  variables {
    gitlab = {
      namespace = "my-gitlab-group"
    }
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].gitlab[0].namespace == "my-gitlab-group"
    error_message = "GitLab namespace was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].gitlab)}"
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].gitlab[0].id == null
    error_message = "GitLab id was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].gitlab)}"
  }
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

# Test bitbucket_cloud dynamic block is created correctly
run "test_bitbucket_cloud_integration" {
  command = plan

  variables {
    bitbucket_cloud = {
      namespace = "my-bitbucket-project"
      id        = "test-bb-cloud-id"
    }
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].bitbucket_cloud[0].namespace == "my-bitbucket-project"
    error_message = "Bitbucket Cloud namespace was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].bitbucket_cloud)}"
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].bitbucket_cloud[0].id == "test-bb-cloud-id"
    error_message = "Bitbucket Cloud id was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].bitbucket_cloud)}"
  }
}

# Test bitbucket_datacenter dynamic block is created correctly
run "test_bitbucket_datacenter_integration" {
  command = plan

  variables {
    bitbucket_datacenter = {
      namespace = "my-bitbucket-dc-project"
      id        = "test-bb-dc-id"
    }
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].bitbucket_datacenter[0].namespace == "my-bitbucket-dc-project"
    error_message = "Bitbucket Data Center namespace was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].bitbucket_datacenter)}"
  }

  assert {
    condition     = spacelift_stack.default["root-module-a-test"].bitbucket_datacenter[0].id == "test-bb-dc-id"
    error_message = "Bitbucket Data Center id was not set correctly: ${jsonencode(spacelift_stack.default["root-module-a-test"].bitbucket_datacenter)}"
  }
}

# Test that VCS blocks are empty when variables are null
run "test_vcs_blocks_empty_when_null" {
  command = plan

  variables {
    github_enterprise    = null
    raw_git             = null
    gitlab              = null
    bitbucket_cloud     = null
    bitbucket_datacenter = null
  }

  assert {
    condition     = length(spacelift_stack.default["root-module-a-test"].github_enterprise) == 0
    error_message = "GitHub Enterprise block should be empty when variable is null: ${jsonencode(spacelift_stack.default["root-module-a-test"].github_enterprise)}"
  }

  assert {
    condition     = length(spacelift_stack.default["root-module-a-test"].raw_git) == 0
    error_message = "Raw Git block should be empty when variable is null: ${jsonencode(spacelift_stack.default["root-module-a-test"].raw_git)}"
  }

  assert {
    condition     = length(spacelift_stack.default["root-module-a-test"].gitlab) == 0
    error_message = "GitLab block should be empty when variable is null: ${jsonencode(spacelift_stack.default["root-module-a-test"].gitlab)}"
  }

  assert {
    condition     = length(spacelift_stack.default["root-module-a-test"].bitbucket_cloud) == 0
    error_message = "Bitbucket Cloud block should be empty when variable is null: ${jsonencode(spacelift_stack.default["root-module-a-test"].bitbucket_cloud)}"
  }

  assert {
    condition     = length(spacelift_stack.default["root-module-a-test"].bitbucket_datacenter) == 0
    error_message = "Bitbucket Data Center block should be empty when variable is null: ${jsonencode(spacelift_stack.default["root-module-a-test"].bitbucket_datacenter)}"
  }
}
