# Azure DevOps Integration Example

This example demonstrates how to configure the spacelift-automation module with Azure DevOps as the version control system.

See Spacelift's full walk through here, https://docs.spacelift.io/integrations/source-control/azure-devops

## Configuration

The key difference from GitHub integration is using the `azure_devops` block instead of `github_enterprise`:

```hcl
azure_devops = {
  project = "MyProject"        # Your Azure DevOps project name
  id      = "integration-id"   # Spacelift Azure DevOps integration ID
}
```

## Usage

1. Update the `azure_devops.project` and `azure_devops.id` values with your Azure DevOps project and Spacelift integration ID
2. Update the `repository` value with your actual repository name
3. Run `terraform init` and `terraform plan` to see what resources will be created
