# `spacelift-automation`

This Terraform root module provides infrastructure automation for Masterpoint's internal projects in [Spacelift](https://docs.spacelift.io/).

## Overview

The `spacelift-automation` root module is designed to streamline the deployment and management of all Spacelift infrastructure, including itself.

At the moment we have one common [spacelift-automation-mp-main](https://masterpointio.app.spacelift.io/stack/spacelift-automation-mp-main) stack that manages all the clients and internal stacks.

It automates the creation of "child" stacks and all the required accompanying Spacelift resources. For each root module configured in the `root-modules/spacelift-automation/tfvars/mp-automation.tfvars` it creates:

1. Spacelift [Stack](https://docs.spacelift.io/concepts/stack/)
   You can think about a stack as a combination of source code, state file and configuration in the form of environment variables and mounted files.
1. Spacelift [Stack Destructor](https://docs.spacelift.io/concepts/stack/stack-dependencies.html#ordered-stack-creation-and-deletion)
   Required to destroy the resources of a Stack before deleting it. Destroying this resource will delete the resources in the stack. If this resource needs to be deleted and the resources in the stacks are to be preserved, ensure that the deactivated attribute is set to true.
1. Spacelift [AWS Role](https://docs.spacelift.io/integrations/cloud-providers/aws#lets-explain)
   Represents cross-account IAM role delegation between the Spacelift worker and an individual stack or module.
1. Spacelift [Mounted File](https://docs.spacelift.io/concepts/configuration/environment.html#mounted-files)
   This feature allows to manage the OpenTofu variables by mounting corresponding tfvars files into a working directory during the run and inject variable definitions into the OpenTofu execution environment.

These files are automatically mounted and available during the OpenTofu plan and apply stages.

⚠️ `spacelift-automation-mp-main` manages all the mounted files and, hence, all the tfvars attached to the stacks. It's crucial to understand that a commit must kick the `spacelift-automation-mp-main` stack first to update all the necessary mounted files, and the dependent stacks run will be started. This flow is managed with Push and Trigger Spacelift Policies. Our custom Policies are stored in [config/spacelift-policies](../../config/spacelift-policies/) directory.

## Usage

Due to the project specifics, Spacelift Automation logic heavily relies on the Git repository structure.
The root module `spacelift-automation` is configured to track all the files in the provided root module directory and create the stack based on the provided configuration (if any).

Let's check the example.
Input repo structure:

```
├── root-modules
│   ├── spacelift-aws-role
│   │   ├── tfvars
│   │   │   └── automation.tfvars
│   │   │   └── dev.tfvars
│   │   ├── variables.tf
│   │   └── versions.tf
│   └── spacelift-spaces
│       └── tfvars
│           └── mp-automation.tfvars
...
```

Root module inputs:

```hcl
aws_role_arn = "arn:aws:iam::755965222190:role/Spacelift"

# GitHub configuration
github_enterprise = {
  namespace = "masterpointio"
}
repository = "spacelift-certification"

# Stacks configurations
root_modules = {
  spacelift-aws-role = {
    common_stack_configs = {
      autodeploy = true
    }
    stacks = {
      automation = {
        description = "The AWS IAM role to assume and put its temporary credentials in `masterpoint-automation` in the runtime environment."
        space_id    = "mp-automation-01J2BSSM6TW46GJ6EJNZW1WP2B"
      }
    }
  }
  spacelift-spaces = {}
}

```

The configuration above creates the following stacks:

- `spacelift-aws-role-automation` with the overridden `autodeploy`, `space_id` and `description` values
- `spacelift-aws-role-dev` with the overriden `autodeploy` valuee
- `spacelift-spaces-mp-automation` with the default stack values

Corresponding Terraform variables are mounted to each stack. For example, the content of the file `root-modules/spacelift-policies/tfvars/push-default.tfvars` will be mounted to the stack `spacelift-policies-push-default`, allowing the Terraform inputs to be provided to the configuration.
