# This Terraform code automates the creation and management of Spacelift stacks based on the structure
# and configurations defined in the Git repository, default Stack values and additional input variables.
# It primarily relies on dynamic local expressions to generate configurations based on the
# input variables and Git structure so it can be consumed by Spacelift resources.
# This module can also manage the automation stack itself, but it should be bootstrapped manually.
#
# It handles the following:
#
# 1. Stack Configurations (see ## Stack Configurations)
# Reads the Spacelift stack configurations strictly based on the root modules structure in Git and file names.
# These are the configurations required to be set for a stack, e.g. project_root, terraform_workspace, root_module.
#
# 2. Common Stack configurations (see ## Common Stack configurations)
# Some configurations are equal across the whole root module, and can be set it on a root module level:
# * Space IDs: in the majority of cases all the workspaces in a root module belong to the same Spacelift space, so
# we allow setting a "global" space_id for all stacks on a root module level.
# * Autodeploy: if all the stacks in a root module should be autodeployed.
# * Administrative: if all the stacks in a root module are administrative, e.g stacks that manage Spacelift resources.
#
# 3. Labels (see ## Labels)
# Generates labels for the stacks based on administrative, dependency, and folder information.
#
# Syntax note:
# The local expression started with an underscore `_` is used to store intermediate values
# that are not directly used in the resource creation.

locals {
  # Constants
  default_workspace_name = "default"
  root_space_id          = "root"

  _multi_instance_structure = var.root_module_structure == "MultiInstance"

  # Read all stack files following the associated root_module_structue convention:
  # MultiInstance: root-module-name/stacks/*.yaml
  # SingleInstance: root-module-name/stack.yaml
  # Example:
  # [
  # MultiInstance:
  #   "../root-module-a/stacks/example.yaml",
  #   "../root-module-a/stacks/common.yaml",
  #   "../root-module-b/stacks/example.yaml",
  #   "../root-module-b/stacks/common.yaml",
  # ] OR [
  # SingleInstance:
  #   "../root-module-a/stack.yaml",
  #   "../root-module-b/stack.yaml",
  # ]
  #   "../root-module-a/stacks/example.yaml",
  #   "../root-module-a/stacks/common.yaml",
  #   "../root-module-b/stacks/example.yaml",
  #   "../root-module-b/stacks/common.yaml",
  # ] OR [
  #   "../root-module-a/stack.yaml",
  #   "../root-module-b/stack.yaml",
  # ]
  _multi_instance_stack_files  = fileset("${path.root}/${var.root_modules_path}/*/stacks", "*.yaml")
  _single_instance_stack_files = fileset("${path.root}/${var.root_modules_path}/*", "stack.yaml")
  _all_stack_files             = local._multi_instance_structure ? local._multi_instance_stack_files : local._single_instance_stack_files

  # Extract the root module name from the stack file path
  _all_root_modules = distinct([for file in local._all_stack_files : dirname(replace(replace(file, "../", ""), "stacks/", ""))])

  # If all root modules are enabled, use all root modules, otherwise use only those given to us
  enabled_root_modules = var.all_root_modules_enabled ? local._all_root_modules : var.enabled_root_modules

  # Read and decode Stack YAML files from the root directory
  # Example:
  # MultiInstance: {
  #   "random-pet" = {
  #     "common.yaml" = {
  #       "stack_settings" = { ... }
  #       ...
  #     }
  #     "example.yaml" = {
  #       "stack_settings" = { ... }
  #       ...
  #     }
  #   }
  # }
  # SingleInstance: {
  #   "random-pet" = {
  #     "default" = { stack_settings = { ... }, ... }
  #   }
  # }
  _multi_instance_root_module_yaml_decoded = {
    for module in local.enabled_root_modules : module => {
      for yaml_file in fileset("${path.root}/${var.root_modules_path}/${module}/stacks", "*.yaml") :
      yaml_file => yamldecode(file("${path.root}/${var.root_modules_path}/${module}/stacks/${yaml_file}"))
    } if local._multi_instance_structure
  }

  _single_instance_root_module_yaml_decoded = {
    for module in local.enabled_root_modules : module => {
      (local.default_workspace_name) = yamldecode(file("${path.root}/${var.root_modules_path}/${module}/stack.yaml"))
    } if !local._multi_instance_structure
  }

  _root_module_yaml_decoded = merge(local._multi_instance_root_module_yaml_decoded, local._single_instance_root_module_yaml_decoded)

  ## Common Stack configurations
  # Retrieve common Stack configurations for each root module.
  # SingleInstance root_module_structure does not support common configs today.
  # Example:
  # {
  #   "random-pet" = {
  #     "stack_settings" = {
  #       "description" = "This stack generates random pet names"
  #       "manage_state" = true
  #     }
  #     "tfvars" = {
  #       "enabled" = false
  #     }
  #   }
  # }
  _common_configs = {
    for module, files in local._root_module_yaml_decoded : module => lookup(files, var.common_config_file, {})
  }

  # If we're SingleInstance, then default_tf_workspace_enabled is true. Otherwise, use given value.
  _default_tf_workspace_enabled = local._multi_instance_structure ? var.default_tf_workspace_enabled : true

  ## Stack Configurations
  # Merge all Stack configurations from the root modules into a single map, and filter out the common config.
  # Example:
  # {
  #   "random-pet-example" = {
  #     "project_root" = "examples/complete/root-modules/random-pet"
  #     "root_module" = "random-pet"
  #     "stack_settings" = {
  #       "manage_state" = true
  #     }
  #     "terraform_workspace" = "example"
  #     "tfvars" = {
  #       "enabled" = true
  #     }
  #   }
  # }
  _root_module_stack_configs = merge([for module, files in local._root_module_yaml_decoded : {
    for file, content in files :
    local._multi_instance_structure ? "${module}-${trimsuffix(file, ".yaml")}" : module =>
    merge(
      {
        # Use specified project_root, if not, build it using the root_modules_path and module name
        "project_root" = try(content.stack_settings.project_root, replace(format("%s/%s", var.root_modules_path, module), "../", "")),
        "root_module"  = module,

        # If default_tf_workspace_enabled is true, use "default" workspace, otherwise our file name is the workspace name
        "terraform_workspace" = try(content.automation_settings.default_tf_workspace_enabled, local._default_tf_workspace_enabled) ? local.default_workspace_name : trimsuffix(file, ".yaml"),

        # tfvars_file_name only pertains to MultiInstance, as SingleInstance expects consumers to use an auto.tfvars file.
        # `yaml` is intentionally used here as we require Stack and `tfvars` config files to be named equally
        "tfvars_file_name" = trimsuffix(file, ".yaml"),
      },
      content,
    ) if file != var.common_config_file
    }
  ]...)

  # Get the configs for each stack, merged with the common configurations
  # Example:
  # {
  #   "random-pet-example" = {
  #     "project_root" = "examples/complete/root-modules/random-pet"
  #     "root_module" = "random-pet"
  #     "stack_settings" = {
  #       "manage_state" = true
  #     }
  #     "terraform_workspace" = "example"
  #     "tfvars" = {
  #       "enabled" = false
  #     }
  #   }
  # }
  configs = {
    for key, value in module.deep : key => value.merged
  }

  # Get the Stacks configs, this is just to improve code readability
  # Example:
  # {
  #   "random-pet-example" = {
  #     "manage_state" = true
  #   }
  # }
  stack_configs = {
    for key, value in local.configs : key => value.stack_settings
  }

  # Get the list of all stack names
  stacks = toset(keys(local.stack_configs))

  ## Labels
  # Сreates a map of administrative labels for each stack that has the administrative property set to true.
  # Example:
  # {
  #   "spacelift-automation-mp-main" = [
  #     "administrative",
  #   ]
  #   "spacelift-policies-notify-tf-completed" = [
  #     "administrative",
  #   ]
  # }

  _administrative_labels = {
    for stack, configs in local.stack_configs : stack => ["administrative"] if tobool(try(configs.administrative, false)) == true
  }

  # Creates a map of `depends-on` labels for each stack based on the root module level dependency configuration.
  # Example:
  # {
  #   "random-pet-example" = [
  #     "depends-on:spacelift-automation-default",
  #   ]
  # }
  _dependency_labels = {
    for stack in local.stacks : stack => [
      "depends-on:spacelift-automation-${terraform.workspace}"
    ]
  }

  # Creates a map of folder labels for each stack based on Git structure for a proper grouping stacks in Spacelift UI.
  # https://docs.spacelift.io/concepts/stack/organizing-stacks#label-based-folders
  # Example:
  # {
  #   "random-pet-example" = [
  #     "folder:random-pet/example",
  #   ]
  # }
  _folder_labels = {
    for stack in local.stacks : stack => [
      local._multi_instance_structure ? "folder:${local.configs[stack].root_module}/${local.configs[stack].tfvars_file_name}" : "folder:${local.configs[stack].root_module}"
    ]
  }

  # Merge all the labels into a single map for each stack.
  # Example:
  # {
  #   "random-pet-example" = tolist([
  #     "folder:random-pet/example",
  #     "depends-on:spacelift-automation-default",
  #   ])
  # }
  labels = {
    for stack in local.stacks :
    stack => compact(flatten([
      lookup(local._administrative_labels, stack, []),
      lookup(local._folder_labels, stack, []),
      lookup(local._dependency_labels, stack, []),
      try(local.stack_configs[stack].labels, []),
      var.labels,
    ]))
  }

  # Merge all before_init steps into a single map for each stack.
  before_init = {
    for stack in local.stacks : stack =>
    # tfvars are implicitly enabled in MultiInstance, which means we include the tfvars copy command in before_init
    # In SingleInstance, we expect the consumer to use an auto.tfvars file, so we don't include the tfvars copy command in before_init
    try(local.configs[stack].automation_settings.tfvars_enabled, local._multi_instance_structure) ?
    compact(concat(
      var.before_init,
      try(local.stack_configs[stack].before_init, []),
      # This command is required for each stack.
      # It copies the tfvars file from the stack's workspace to the root module's directory
      # and renames it to `spacelift.auto.tfvars` to automatically load variable definitions for each run/task.
      ["cp tfvars/${local.configs[stack].tfvars_file_name}.tfvars spacelift.auto.tfvars"],
      )) : compact(concat(
      var.before_init,
      try(local.stack_configs[stack].before_init, []),
    ))
  }

  ## Handle space lookups

  # Allow usage of space_name along with space_id.
  # A space_id is long and hard to look at in the stack.yaml file, so pass in the space_name and it will be resolved to the space_id, which will be consumed by the `spacelife_stack` resource.
  space_name_to_id = {
    for space in data.spacelift_spaces.all.spaces :
    space.name => space.space_id
  }

  # Helper for property resolution with fallback to defaults
  stack_property_resolver = {
    for stack in local.stacks : stack => {
      # Simple property resolution with fallback
      administrative                   = try(local.stack_configs[stack].administrative, var.administrative)
      autoretry                        = try(local.stack_configs[stack].autoretry, var.autoretry)
      additional_project_globs         = try(local.stack_configs[stack].additional_project_globs, var.additional_project_globs)
      autodeploy                       = try(local.stack_configs[stack].autodeploy, var.autodeploy)
      branch                           = try(local.stack_configs[stack].branch, var.branch)
      enable_local_preview             = try(local.stack_configs[stack].enable_local_preview, var.enable_local_preview)
      enable_well_known_secret_masking = try(local.stack_configs[stack].enable_well_known_secret_masking, var.enable_well_known_secret_masking)
      github_action_deploy             = try(local.stack_configs[stack].github_action_deploy, var.github_action_deploy)
      manage_state                     = try(local.stack_configs[stack].manage_state, var.manage_state)
      protect_from_deletion            = try(local.stack_configs[stack].protect_from_deletion, var.protect_from_deletion)
      repository                       = try(local.stack_configs[stack].repository, var.repository)
      runner_image                     = try(local.stack_configs[stack].runner_image, var.runner_image)
      terraform_smart_sanitization     = try(local.stack_configs[stack].terraform_smart_sanitization, var.terraform_smart_sanitization)
      terraform_version                = try(local.stack_configs[stack].terraform_version, var.terraform_version)
      worker_pool_id                   = try(local.stack_configs[stack].worker_pool_id, var.worker_pool_id)

      # AWS Integration properties
      aws_integration_id = try(local.stack_configs[stack].aws_integration_id, var.aws_integration_id)

      # Drift detection properties
      drift_detection_ignore_state = try(local.stack_configs[stack].drift_detection_ignore_state, var.drift_detection_ignore_state)
      drift_detection_reconcile    = try(local.stack_configs[stack].drift_detection_reconcile, var.drift_detection_reconcile)
      drift_detection_schedule     = try(local.stack_configs[stack].drift_detection_schedule, var.drift_detection_schedule)
      drift_detection_timezone     = try(local.stack_configs[stack].drift_detection_timezone, var.drift_detection_timezone)

      # Destructor properties
      destructor_deactivated = try(local.stack_configs[stack].destructor_deactivated, var.destructor_deactivated)
    }
  }

  # Helper for array merging with fallback
  stack_array_merger = {
    for stack in local.stacks : stack => {
      after_apply    = compact(concat(try(local.stack_configs[stack].after_apply, []), var.after_apply))
      after_destroy  = compact(concat(try(local.stack_configs[stack].after_destroy, []), var.after_destroy))
      after_init     = compact(concat(try(local.stack_configs[stack].after_init, []), var.after_init))
      after_perform  = compact(concat(try(local.stack_configs[stack].after_perform, []), var.after_perform))
      after_plan     = compact(concat(try(local.stack_configs[stack].after_plan, []), var.after_plan))
      after_run      = compact(concat(try(local.stack_configs[stack].after_run, []), var.after_run))
      before_apply   = compact(coalesce(try(local.stack_configs[stack].before_apply, []), var.before_apply))
      before_destroy = compact(coalesce(try(local.stack_configs[stack].before_destroy, []), var.before_destroy))
      before_perform = compact(coalesce(try(local.stack_configs[stack].before_perform, []), var.before_perform))
      before_plan    = compact(coalesce(try(local.stack_configs[stack].before_plan, []), var.before_plan))
    }
  }

  resolved_space_ids = {
    for stack in local.stacks : stack => coalesce(
      try(local.stack_configs[stack].space_id, null),                           # space_id always takes precedence since it's the most explicit
      try(local.space_name_to_id[local.stack_configs[stack].space_name], null), # Then try to look up space_name from the stack.yaml to ID
      var.space_id,
      try(local.space_name_to_id[var.space_name], null), # Then try to look up the space_name global variable to ID
      local.root_space_id                                # If no space_id or space_name is provided, default to the root space
    )
  }

  ## Filter integration + drift detection stacks

  aws_integration_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.aws_integration_enabled, var.aws_integration_enabled)
  }
  drift_detection_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.drift_detection_enabled, var.drift_detection_enabled)
  }
  destructor_stacks = {
    for stack, config in local.stack_configs :
    stack => config if try(config.destructor_enabled, var.destructor_enabled)
  }
}

check "spaces_enforce_mutual_exclusivity" {
  assert {
    condition     = var.space_id == null || var.space_name == null
    error_message = "space_id and space_name are mutually exclusive."
  }
}

# Perform deep merge for common configurations and stack configurations
module "deep" {
  source   = "cloudposse/config/yaml//modules/deepmerge"
  version  = "1.0.2"
  for_each = local._root_module_stack_configs

  # Here is where some magic happens...
  # The common config is the base config, it is overridden by the static StackConfig
  # Runtime overrides are applied last (should be used sparingly), they overwrite all values for the Stack
  maps = [
    local._common_configs[each.value.root_module],
    each.value,
    try(jsondecode(data.jsonschema_validator.runtime_overrides[each.value.root_module].validated), {}),
  ]

  # To support merging labels from common.yaml, we need lists to append instead of overwrite
  append_list_enabled = true
}

resource "spacelift_stack" "default" {
  for_each = local.stacks

  administrative                   = local.stack_property_resolver[each.key].administrative
  additional_project_globs         = local.stack_property_resolver[each.key].additional_project_globs
  after_apply                      = local.stack_array_merger[each.key].after_apply
  after_destroy                    = local.stack_array_merger[each.key].after_destroy
  after_init                       = local.stack_array_merger[each.key].after_init
  after_perform                    = local.stack_array_merger[each.key].after_perform
  after_plan                       = local.stack_array_merger[each.key].after_plan
  after_run                        = local.stack_array_merger[each.key].after_run
  autodeploy                       = local.stack_property_resolver[each.key].autodeploy
  autoretry                        = local.stack_property_resolver[each.key].autoretry
  before_apply                     = local.stack_array_merger[each.key].before_apply
  before_destroy                   = local.stack_array_merger[each.key].before_destroy
  before_init                      = local.before_init[each.key]
  before_perform                   = local.stack_array_merger[each.key].before_perform
  before_plan                      = local.stack_array_merger[each.key].before_plan
  branch                           = local.stack_property_resolver[each.key].branch
  enable_local_preview             = local.stack_property_resolver[each.key].enable_local_preview
  enable_well_known_secret_masking = local.stack_property_resolver[each.key].enable_well_known_secret_masking
  github_action_deploy             = local.stack_property_resolver[each.key].github_action_deploy
  labels                           = local.labels[each.key]
  manage_state                     = local.stack_property_resolver[each.key].manage_state
  name                             = each.key
  project_root                     = local.configs[each.key].project_root
  protect_from_deletion            = local.stack_property_resolver[each.key].protect_from_deletion
  repository                       = local.stack_property_resolver[each.key].repository
  runner_image                     = local.stack_property_resolver[each.key].runner_image
  space_id                         = local.resolved_space_ids[each.key]
  terraform_smart_sanitization     = local.stack_property_resolver[each.key].terraform_smart_sanitization
  terraform_version                = local.stack_property_resolver[each.key].terraform_version
  terraform_workflow_tool          = var.terraform_workflow_tool
  terraform_workspace              = local.configs[each.key].terraform_workspace
  worker_pool_id                   = local.stack_property_resolver[each.key].worker_pool_id

  # Usage of `templatestring` requires OpenTofu 1.7 and Terraform 1.9 or later.
  description = coalesce(
    try(local.stack_configs[each.key].description, null),
    try(templatestring(var.description, local.configs[each.key]), null),
    "Managed by spacelift-automation Terraform root module."
  )

  dynamic "github_enterprise" {
    for_each = var.github_enterprise != null ? [var.github_enterprise] : []
    content {
      namespace = github_enterprise.value["namespace"]
      id        = github_enterprise.value["id"]
    }
  }
}

# The Spacelift Destructor is a feature designed to automatically clean up the resources no longer managed by our IaC.
# Don't toggle the creation/destruction of this resource with var.destructor_enabled,
# as it will delete all resources in the stack when toggled from 'true' to 'false'.
# Use the 'deactivated' attribute to disable the stack destructor functionality instead.
# https://github.com/spacelift-io/terraform-provider-spacelift/blob/master/spacelift/resource_stack_destructor.go
resource "spacelift_stack_destructor" "default" {
  for_each = local.destructor_stacks

  stack_id    = spacelift_stack.default[each.key].id
  deactivated = local.stack_property_resolver[each.key].destructor_deactivated

  # `depends_on` should be used to make sure that all necessary resources (environment variables, roles, integrations, etc.)
  # are still in place when the destruction run is executed.
  # See https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/stack_destructor
  depends_on = [
    spacelift_drift_detection.default,
    spacelift_aws_integration_attachment.default
  ]
}

resource "spacelift_aws_integration_attachment" "default" {
  for_each = local.aws_integration_stacks

  integration_id = local.stack_property_resolver[each.key].aws_integration_id
  stack_id       = spacelift_stack.default[each.key].id
  read           = var.aws_integration_attachment_read
  write          = var.aws_integration_attachment_write
}

resource "spacelift_drift_detection" "default" {
  for_each = local.drift_detection_stacks

  stack_id     = spacelift_stack.default[each.key].id
  ignore_state = local.stack_property_resolver[each.key].drift_detection_ignore_state
  reconcile    = local.stack_property_resolver[each.key].drift_detection_reconcile
  schedule     = local.stack_property_resolver[each.key].drift_detection_schedule
  timezone     = local.stack_property_resolver[each.key].drift_detection_timezone

  lifecycle {
    precondition {
      condition     = alltrue([for schedule in local.stack_property_resolver[each.key].drift_detection_schedule : can(regex("^([0-9,\\-*/]+\\s+){4}[0-9,\\-*/]+$", schedule))])
      error_message = "Invalid cron schedule format for drift detection"
    }
  }
}

resource "spacelift_space" "default" {
  for_each = var.spaces

  name             = each.key
  description      = each.value.description
  inherit_entities = each.value.inherit_entities
  labels           = each.value.labels
  parent_space_id  = each.value.parent_space_id
}
