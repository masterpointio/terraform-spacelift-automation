# `spacelift-automation`

[![Release](https://img.shields.io/github/release/masterpointio/terraform-spacelift-automation.svg)](https://github.com/masterpointio/terraform-spacelift-automation/releases/latest)

This Terraform child module provides infrastructure automation for projects in [Spacelift](https://docs.spacelift.io/).

## Overview

This `spacelift-automation` child module is designed to streamline the deployment and management of all Spacelift infrastructure, including creating a Spacelift Stack to manage itself.

Check out our quick introduction to this child module here: [![[External] terraform-spacelift-automation quick intro - Watch Video](https://cdn.loom.com/sessions/thumbnails/8de21afb732048a58fdee90042b4840f-11908d1d42de3247-full-play.gif)](https://www.loom.com/share/8de21afb732048a58fdee90042b4840f)

It automates the creation of "child" stacks and all the required accompanying Spacelift resources. For each enabled root module it creates:

1. [Spacelift Stack](https://docs.spacelift.io/concepts/stack/)
   You can think about a stack as a combination of source code, state file and configuration in the form of environment variables and mounted files.
2. [Spacelift Stack Destructor](https://docs.spacelift.io/concepts/stack/stack-dependencies.html#ordered-stack-creation-and-deletion)
   Required to destroy the resources of a Stack before deleting it. Destroying this resource will delete the resources in the stack. If this resource needs to be deleted and the resources in the stacks are to be preserved, ensure that the deactivated attribute is set to true.
3. [Spacelift AWS Integration Attachment](https://docs.spacelift.io/integrations/cloud-providers/aws#lets-explain)
   Associates a specific AWS IAM role with a stack to allow it to assume that role. The IAM role typically has permissions to manage specific AWS resources, and Spacelift assumes this role to run the operations required by the stack.
4. [Spacelift Initialization Hook](https://docs.spacelift.io/concepts/run#initializing)
   Prepares your environment before executing infrastructure code. This custom script copies corresponding Terraform tfvars files into a working directory before any Spacelift run or task as a `spacelift.auto.tfvars` file. This ensures your tfvars are [automatically loaded](https://opentofu.org/docs/v1.7/language/values/variables/#variable-definitions-tfvars-files) into the OpenTofu/Terraform execution environment.

## Usage

Spacelift Automation logic is opinionated and heavily relies on certain repository structures.
This module is configured to track all the files in the given root module directory and create Spacelift Stacks based on the provided configuration.

We support the following root module directory structures, which are controlled by the `var.root_modules_structure` variable:

### `MultiInstance` (the default)

This is the default structure that we expect and recommend. This is intended for root modules that manage multiple state files (instances) through [workspaces](https://opentofu.org/docs/cli/workspaces/) or [Dynamic Backend configurations](https://opentofu.org/docs/intro/whats-new/#early-variablelocals-evaluation).

Structure requirements:

- Stack configs are placed in `<root_modules_path>/<root_module>/stacks` directory for each workspace / instance of that stack. e.g. `root-modules/k8s-cluster/stacks/dev.yaml` and `root-modules/k8s-cluster/stacks/stage.yaml`
- Terraform variables are placed in `<root_modules_path>/<root_module>/tfvars` directory for each workspace / instance of that stack. e.g. `root-modules/k8s-cluster/tfvars/dev.tfvars` and `root-modules/k8s-cluster/tfvars/stage.tfvars`
- Stack config files and tfvars files must be equal to OpenTofu/Terraform workspace, e.g. `stacks/dev.yaml` and `tfvars/dev.tfvars` for a workspace named `dev`.
- Common configs are placed in `<root_modules_path>/<root_module>/stacks/common.yaml` file (or `var.common_config_file` value). This is useful when you know that some values should be shared across all the stacks created for a root module. For example, all stacks that manage Spacelift Policies must use the `administrative: true` setting or all stacks must share the same labels.

We have an example of this structure in the [examples/complete](./examples/complete/root-modules/), which looks like the following:

```sh
├── root-modules
│   ├── spacelift-aws-role
│   │   ├── stacks
│   │   │   └── dev.yaml
│   │   │   └── stage.yaml
│   │   │   └── common.yaml
│   │   ├── tfvars
│   │   │   └── dev.tfvars
│   │   │   └── stage.tfvars
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── versions.tf
│   ├── k8s-cluster
│   │   ├── stacks
│   │   │   └── dev.yaml
│   │   │   └── prod.yaml
│   │   │   └── common.yaml
│   │   ├── tfvars
│   │   │   └── dev.tfvars
│   │   │   └── prod.tfvars
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── versions.tf
...
```

The `spacelift-automation/main.tf` file looks something like this:

```hcl
github_enterprise = {
  namespace = "masterpointio"
}
repository = "terraform-spacelift-automation"

# Stacks configurations
root_modules_path        = "root-modules"
all_root_modules_enabled = true

aws_integration_id = "ZDPP8SKNVG0G27T4"
```

The configuration above creates the following stacks:

- `spacelift-aws-role-dev`
- `spacelift-aws-role-stage`
- `k8s-cluster-dev`
- `k8s-cluster-prod`

These stacks have the following configuration:

- Stacks track changes in GitHub repo `github.com/masterpointio/terraform-spacelift-automation`, branch `main` (the default), and directrory `root-modules`.
- Common configuration is defined in `root-modules/spacelift-aws-role/stacks/common.yaml` and applied to both Stacks. However, if there is an override in a Stack config (e.g. `root-modules/spacelift-aws-role/stacks/dev.yaml`), it takes precedence over common configs.
- Corresponding Terraform variables are generated by an [Initialization Hook](https://docs.spacelift.io/concepts/run#initializing) and placed in the root of each Stack's working directory during each run or task. For example, the content of the file `root-modules/spacelift-aws-role/tfvars/dev.tfvars` will be copied to working directory of the Stack `spacelift-aws-role-dev` as file `spacelift.auto.tfvars` allowing the OpenTofu/Terraform inputs to be automatically loaded.
  - If you would like to disable this functionality, you can set `tfvars.enabled` in the Stack's YAML file to `false`.

### `SingleInstance`

This is a special case where each root module directory only manages one state file (instance). Each time you want to create a new instance of a root module, you need to create a new directory with the same code and change your inputs. **We do not recommend this structure** as it is less flexible and easily leads to anti-patterns, but it is supported.

Structure requirements:

- Stack configs are placed in `<root_modules_path>/<root_module>/stack.yaml` directory. e.g. `root-modules/rds-cluster/stack.yaml`
- Tfvars values are not supported in this structure. In this structure, we suggest you just add your tfvars as `***.auto.tfvars` or hardcode your values directly in root module code.

Here is an example of this structure that we have in the [examples/single-instance](./examples/single-instance/) directory:

```sh
├── root-modules
│   ├── spacelift-automation
│   │   ├── stack.yaml
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── versions.tf
│   ├── rds-cluster-dev
│   │   ├── stack.yaml
│   │   ├── main.tf
│   │   └── versions.tf
│   ├── rds-cluster-prod
│   │   ├── stack.yaml
│   │   ├── main.tf
│   │   └── versions.tf
│   ├── random-pet
│   │   ├── stack.yaml
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── versions.tf
...
```

The configuration above creates the following Spacelift Stacks:

- `spacelift-automation`
- `rds-cluster-dev`
- `rds-cluster-prod`
- `random-pet`

These stacks will be configured using the settings in the `stack.yaml` file.

## FAQs

### Can I create a Spacelift Stack for Spacelift Automation? (Recommended)

Spacelift Automation can manage itself as a Stack as well, and we recommend this so you can fully automate your Stack management upon merging to your given branch. Follow these steps to achieve that:

1. Create a new vanilla OpenTofu/Terraform root module in `<root_modules_path>/spacelift-automation` that consumes this child module and supplies the necessary configuration for your unique setup. e.g.

   ```hcl
   # root-modules/spacelift-automation/main.tf

   module "spacelift-automation" {
     source  = "masterpointio/automation/spacelift"
     version = "x.x.x" # Always pin a version, use the latest version from the release page.

     # GitHub configuration
     github_enterprise = {
       namespace = "masterpointio"
     }
     repository = "your-infrastructure-repo"

     # Stacks configurations
     root_modules_path        = "../../root-modules"
     all_root_modules_enabled = true

     aws_integration_id = "ZDPP8SKNVG0G27T4"
   }
   ```

2. Optionally, create a Terraform workspace that will be used for your Automation configuration, e.g.:

   ```sh
   tofu workspace new main
   ```

   Remember that Stack config and tfvars file name must be equal to the workspace e.g. `main.yaml` and `main.tfvars`. If you choose not to create a new workspace, this can be `default.yaml` and `default.tfvars`.

3. Apply the `spacelift-automation` root module.
4. Move the Automation configs to the `<root-modules>/spacelift-automation/stacks` directory and push the changes to the tracked repo and branch.
5. After pushed to your repo's tracked branch, Spacelift Automation will track the addition of new root modules and create Stacks for them.

Check out an example configuration in the [examples/complete](./examples/complete/root-modules/spacelift-automation/tfvars/example.tfvars).

<!-- NOTE to Masterpoint team: We might want to create a small wrapper to automatize this using Taskit. On hold for now. -->

### What goes in a Stack config file? e.g. `stacks/dev.yaml`, `stacks/common.yaml`, `stack.yaml`, etc

Most settings that you would set on [the Spacelift Stack resource](https://search.opentofu.org/provider/spacelift-io/spacelift/latest/docs/resources/stack) are supported. Additionally, you can include certain Stack specific settings that will override this module's defaults like `default_tf_workspace_enabled`, `tfvars.enabled`, `space_name`, and similar. See the code for full details.

### Why are variable values provided separately in `tfvars/` and not in the `yaml` file?

This is to support easy local and outside-spacelift operations. Keeping variable values in a `tfvars` file per workspace allows you to simply pass that file to the relevant CLI command locally via the `-var-file` option so that you don't need to provide values individually. e.g. `tofu plan -var-file=tfvars/dev.tfvars`

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

| Name                                                                     | Version |
| ------------------------------------------------------------------------ | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6  |
| <a name="requirement_spacelift"></a> [spacelift](#requirement_spacelift) | >= 1.14 |

## Providers

| Name                                                               | Version |
| ------------------------------------------------------------------ | ------- |
| <a name="provider_spacelift"></a> [spacelift](#provider_spacelift) | 1.19.0  |

## Modules

| Name                                            | Source                                    | Version |
| ----------------------------------------------- | ----------------------------------------- | ------- |
| <a name="module_deep"></a> [deep](#module_deep) | cloudposse/config/yaml//modules/deepmerge | 1.0.2   |

## Resources

| Name                                                                                                                                                            | Type     |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [spacelift_aws_integration_attachment.default](https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/aws_integration_attachment) | resource |
| [spacelift_drift_detection.default](https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/drift_detection)                       | resource |
| [spacelift_stack.default](https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/stack)                                           | resource |
| [spacelift_stack_destructor.default](https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/stack_destructor)                     | resource |

## Inputs

| Name                                                                                                                              | Description                                                                                                                                                                                                                                                                                                                                                                               | Type                                                                           | Default                                                    | Required |
| --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------- | :------: |
| <a name="input_additional_project_globs"></a> [additional_project_globs](#input_additional_project_globs)                         | Project globs is an optional list of paths to track stack changes of outside of the project root. Push policies are another alternative to track changes in additional paths.                                                                                                                                                                                                             | `set(string)`                                                                  | `[]`                                                       |    no    |
| <a name="input_administrative"></a> [administrative](#input_administrative)                                                       | Flag to mark the stack as administrative                                                                                                                                                                                                                                                                                                                                                  | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_after_apply"></a> [after_apply](#input_after_apply)                                                                | List of after-apply scripts                                                                                                                                                                                                                                                                                                                                                               | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_after_destroy"></a> [after_destroy](#input_after_destroy)                                                          | List of after-destroy scripts                                                                                                                                                                                                                                                                                                                                                             | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_after_init"></a> [after_init](#input_after_init)                                                                   | List of after-init scripts                                                                                                                                                                                                                                                                                                                                                                | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_after_perform"></a> [after_perform](#input_after_perform)                                                          | List of after-perform scripts                                                                                                                                                                                                                                                                                                                                                             | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_after_plan"></a> [after_plan](#input_after_plan)                                                                   | List of after-plan scripts                                                                                                                                                                                                                                                                                                                                                                | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_all_root_modules_enabled"></a> [all_root_modules_enabled](#input_all_root_modules_enabled)                         | When set to true, all subdirectories in root_modules_path will be treated as root modules.                                                                                                                                                                                                                                                                                                | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_autodeploy"></a> [autodeploy](#input_autodeploy)                                                                   | Flag to enable/disable automatic deployment of the stack                                                                                                                                                                                                                                                                                                                                  | `bool`                                                                         | `true`                                                     |    no    |
| <a name="input_autoretry"></a> [autoretry](#input_autoretry)                                                                      | Flag to enable/disable automatic retry of the stack                                                                                                                                                                                                                                                                                                                                       | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_aws_integration_attachment_read"></a> [aws_integration_attachment_read](#input_aws_integration_attachment_read)    | Indicates whether this attachment is used for read operations.                                                                                                                                                                                                                                                                                                                            | `bool`                                                                         | `true`                                                     |    no    |
| <a name="input_aws_integration_attachment_write"></a> [aws_integration_attachment_write](#input_aws_integration_attachment_write) | Indicates whether this attachment is used for write operations.                                                                                                                                                                                                                                                                                                                           | `bool`                                                                         | `true`                                                     |    no    |
| <a name="input_aws_integration_enabled"></a> [aws_integration_enabled](#input_aws_integration_enabled)                            | Indicates whether the AWS integration is enabled.                                                                                                                                                                                                                                                                                                                                         | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_aws_integration_id"></a> [aws_integration_id](#input_aws_integration_id)                                           | ID of the AWS integration to attach.                                                                                                                                                                                                                                                                                                                                                      | `string`                                                                       | `null`                                                     |    no    |
| <a name="input_before_apply"></a> [before_apply](#input_before_apply)                                                             | List of before-apply scripts                                                                                                                                                                                                                                                                                                                                                              | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_before_destroy"></a> [before_destroy](#input_before_destroy)                                                       | List of before-destroy scripts                                                                                                                                                                                                                                                                                                                                                            | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_before_init"></a> [before_init](#input_before_init)                                                                | List of before-init scripts                                                                                                                                                                                                                                                                                                                                                               | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_before_perform"></a> [before_perform](#input_before_perform)                                                       | List of before-perform scripts                                                                                                                                                                                                                                                                                                                                                            | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_before_plan"></a> [before_plan](#input_before_plan)                                                                | List of before-plan scripts                                                                                                                                                                                                                                                                                                                                                               | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_branch"></a> [branch](#input_branch)                                                                               | Specify which branch to use within the infrastructure repository.                                                                                                                                                                                                                                                                                                                         | `string`                                                                       | `"main"`                                                   |    no    |
| <a name="input_common_config_file"></a> [common_config_file](#input_common_config_file)                                           | Name of the common configuration file for the stack across a root module.                                                                                                                                                                                                                                                                                                                 | `string`                                                                       | `"common.yaml"`                                            |    no    |
| <a name="input_default_tf_workspace_enabled"></a> [default_tf_workspace_enabled](#input_default_tf_workspace_enabled)             | Enables the use of `default` Terraform workspace instead of managing multiple workspaces within a root module.<br/><br/>NOTE: We encourage the use of Terraform workspaces to manage multiple environments.<br/>However, you will want to disable this behavior if you're utilizing different backends for each instance<br/>of your root modules (we call this "Dynamic Backends").      | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_description"></a> [description](#input_description)                                                                | Description of the stack                                                                                                                                                                                                                                                                                                                                                                  | `string`                                                                       | `"Managed by spacelift-automation Terraform root module."` |    no    |
| <a name="input_destructor_enabled"></a> [destructor_enabled](#input_destructor_enabled)                                           | Flag to enable/disable the destructor for the Stack.                                                                                                                                                                                                                                                                                                                                      | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_drift_detection_enabled"></a> [drift_detection_enabled](#input_drift_detection_enabled)                            | Flag to enable/disable Drift Detection configuration for a Stack.                                                                                                                                                                                                                                                                                                                         | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_drift_detection_ignore_state"></a> [drift_detection_ignore_state](#input_drift_detection_ignore_state)             | Controls whether drift detection should be performed on a stack<br/>in any final state instead of just 'Finished'.                                                                                                                                                                                                                                                                        | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_drift_detection_reconcile"></a> [drift_detection_reconcile](#input_drift_detection_reconcile)                      | Flag to enable/disable automatic reconciliation of drifts.                                                                                                                                                                                                                                                                                                                                | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_drift_detection_schedule"></a> [drift_detection_schedule](#input_drift_detection_schedule)                         | The schedule for drift detection.                                                                                                                                                                                                                                                                                                                                                         | `list(string)`                                                                 | <pre>[<br/> "0 4 * * *"<br/>]</pre>                        |    no    |
| <a name="input_drift_detection_timezone"></a> [drift_detection_timezone](#input_drift_detection_timezone)                         | The timezone for drift detection.                                                                                                                                                                                                                                                                                                                                                         | `string`                                                                       | `"UTC"`                                                    |    no    |
| <a name="input_enable_local_preview"></a> [enable_local_preview](#input_enable_local_preview)                                     | Indicates whether local preview runs can be triggered on this Stack.                                                                                                                                                                                                                                                                                                                      | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_enable_well_known_secret_masking"></a> [enable_well_known_secret_masking](#input_enable_well_known_secret_masking) | Indicates whether well-known secret masking is enabled.                                                                                                                                                                                                                                                                                                                                   | `bool`                                                                         | `true`                                                     |    no    |
| <a name="input_enabled_root_modules"></a> [enabled_root_modules](#input_enabled_root_modules)                                     | List of root modules where to look for stack config files.<br/>Ignored when all_root_modules_enabled is true.<br/>Example: ["spacelift-automation", "k8s-cluster"]                                                                                                                                                                                                                        | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_github_action_deploy"></a> [github_action_deploy](#input_github_action_deploy)                                     | Indicates whether GitHub users can deploy from the Checks API.                                                                                                                                                                                                                                                                                                                            | `bool`                                                                         | `true`                                                     |    no    |
| <a name="input_github_enterprise"></a> [github_enterprise](#input_github_enterprise)                                              | The GitHub VCS settings                                                                                                                                                                                                                                                                                                                                                                   | <pre>object({<br/> namespace = string<br/> id = optional(string)<br/> })</pre> | `null`                                                     |    no    |
| <a name="input_labels"></a> [labels](#input_labels)                                                                               | List of labels to apply to the stacks.                                                                                                                                                                                                                                                                                                                                                    | `list(string)`                                                                 | `[]`                                                       |    no    |
| <a name="input_manage_state"></a> [manage_state](#input_manage_state)                                                             | Determines if Spacelift should manage state for this stack.                                                                                                                                                                                                                                                                                                                               | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_protect_from_deletion"></a> [protect_from_deletion](#input_protect_from_deletion)                                  | Protect this stack from accidental deletion. If set, attempts to delete this stack will fail.                                                                                                                                                                                                                                                                                             | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_repository"></a> [repository](#input_repository)                                                                   | The name of your infrastructure repo                                                                                                                                                                                                                                                                                                                                                      | `string`                                                                       | n/a                                                        |   yes    |
| <a name="input_root_module_structure"></a> [root_module_structure](#input_root_module_structure)                                  | The root module structure of the Stacks that you're reading in. See README for full details.<br/><br/>MultiInstance - You're using Workspaces or Dynamic Backend configuration to create multiple instances of the same root module code.<br/>SingleInstance - You're using copies of a root module and your directory structure to create multiple instances of the same Terraform code. | `string`                                                                       | `"MultiInstance"`                                          |    no    |
| <a name="input_root_modules_path"></a> [root_modules_path](#input_root_modules_path)                                              | The path, relative to the root of the repository, where the root module can be found.                                                                                                                                                                                                                                                                                                     | `string`                                                                       | `"root-modules"`                                           |    no    |
| <a name="input_runner_image"></a> [runner_image](#input_runner_image)                                                             | URL of the Docker image used to process Runs. Defaults to `null` which is Spacelift's standard (Alpine) runner image.                                                                                                                                                                                                                                                                     | `string`                                                                       | `null`                                                     |    no    |
| <a name="input_space_id"></a> [space_id](#input_space_id)                                                                         | Place the created stacks in the specified space_id. Mutually exclusive with space_name.                                                                                                                                                                                                                                                                                                   | `string`                                                                       | `null`                                                     |    no    |
| <a name="input_space_name"></a> [space_name](#input_space_name)                                                                   | Place the created stacks in the specified space_name. Mutually exclusive with space_id.                                                                                                                                                                                                                                                                                                   | `string`                                                                       | `null`                                                     |    no    |
| <a name="input_terraform_smart_sanitization"></a> [terraform_smart_sanitization](#input_terraform_smart_sanitization)             | Indicates whether runs on this will use terraform's sensitive value system to sanitize<br/>the outputs of Terraform state and plans in spacelift instead of sanitizing all fields.                                                                                                                                                                                                        | `bool`                                                                         | `false`                                                    |    no    |
| <a name="input_terraform_version"></a> [terraform_version](#input_terraform_version)                                              | Terraform version to use.                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                       | `"1.7.2"`                                                  |    no    |
| <a name="input_terraform_workflow_tool"></a> [terraform_workflow_tool](#input_terraform_workflow_tool)                            | Defines the tool that will be used to execute the workflow.<br/>This can be one of OPEN_TOFU, TERRAFORM_FOSS or CUSTOM.                                                                                                                                                                                                                                                                   | `string`                                                                       | `"OPEN_TOFU"`                                              |    no    |
| <a name="input_worker_pool_id"></a> [worker_pool_id](#input_worker_pool_id)                                                       | ID of the worker pool to use.<br/>NOTE: worker_pool_id is required when using a self-hosted instance of Spacelift.                                                                                                                                                                                                                                                                        | `string`                                                                       | `null`                                                     |    no    |

## Outputs

| Name                                                                                | Description                                                                                                                                                   |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <a name="output_spacelift_stacks"></a> [spacelift_stacks](#output_spacelift_stacks) | A map of Spacelift stacks with selected attributes.<br/>To reduce the risk of accidentally exporting sensitive data, only a subset of attributes is exported. |

## Contributing

Contributions are welcome and appreciated!

Found an issue or want to request a feature? [Open an issue](https://github.com/masterpointio/terraform-spacelift-automation/issues/new)

Want to fix a bug you found or add some functionality? Fork, clone, commit, push, and PR and we'll check it out.

If you have any issues or are waiting a long time for a PR to get merged then feel free to ping us at [hello@masterpoint.io](mailto:hello@masterpoint.io).

## Built By

[![Masterpoint Logo](https://i.imgur.com/RDLnuQO.png)](https://masterpoint.io)
