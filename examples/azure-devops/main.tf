module "automation_azure_devops" {
  source = "../../"

  azure_devops = {
    project = "MyProject-Spacelift-Project"
    id      = "name-of-your-azure-devops-integration-in-spacelift"
  }
  repository = "MyProject-Spacelift-Project"
  branch     = "main"

  root_modules_path        = "../../examples/complete/root-modules"
  all_root_modules_enabled = true

  aws_integration_id      = "01JEC7ZACVKHTSVY4NF8QNZVVB"
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
  }
}
