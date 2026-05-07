module "automation" {
  source = "../../../../"

  github_enterprise = {
    namespace = "masterpointio"
  }
  repository = "terraform-spacelift-automation"
  branch     = "main"

  # This example's spacelift-automation module lives many directories deep, so the
  # discovery path is relative to *this module*, while project_root_prefix points to the
  # path Spacelift uses inside the repo.
  root_modules_discovery_path = "../../../../examples/complete/root-modules"
  project_root_prefix         = "examples/complete/root-modules"
  all_root_modules_enabled    = true

  aws_integration_id      = "YOUR_AWS_INTEGRATION_ID"
  aws_integration_enabled = true
}

module "spacelift_policies" {
  source  = "masterpointio/spacelift/policies"
  version = "0.2.0"

  policies = {
    "access-default" = {
      body        = <<-EOT
        package spacelift
        default allow = true
      EOT
      type        = "ACCESS"
      description = "Policy allowing access to resources"
      labels      = ["team:sre", "env:dev"]
    }

    trigger-administrative = {
      body_url = "https://raw.githubusercontent.com/cloudposse/terraform-spacelift-cloud-infrastructure-automation/1.6.0/catalog/policies/trigger.administrative.rego"
      type     = "TRIGGER"
      labels   = ["autoattach:*"] # Showcasing how to attach to ALL stacks
    }
    plan-deny-static-aws-creds = {
      body_file = "./policies/plan.deny-static-aws-creds.rego"
      type      = "PLAN"
      labels    = ["autoattach:iam"] # Showcasing how to autoattach to all stacks with "iam" label
    }
    push-default = {
      body_file = "./policies/push.default.rego"
      type      = "GIT_PUSH"
      labels    = ["autoattach:*"]
    }
    trigger-dependencies = {
      body_file = "./policies/trigger.dependencies.rego"
      type      = "TRIGGER"
      labels    = ["autoattach:*"]
    }
  }
}
