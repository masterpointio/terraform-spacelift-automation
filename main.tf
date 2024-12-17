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
  _all_stack_files     = fileset("${path.root}/${var.root_modules_path}/*/stacks", "*.yaml")
  _all_root_modules    = distinct([for file in local._all_stack_files : dirname(replace(replace(file, "../", ""), "stacks/", ""))])
  enabled_root_modules = var.all_root_modules_enabled ? local._all_root_modules : var.enabled_root_modules

  # Read and decode Stack YAML files from the root directory
  # Example:
  # {
  #   "random-pet" = {
  #     "common.yaml" = {
  #       "stack_settings" = {
  #         "description" = "This stack generates random pet names"
  #         "manage_state" = true
  #       }
  #       "tfvars" = {
  #         "enabled" = false
  #       }
  #     }
  #     "example.yaml" = {
  #       "stack_settings" = {
  #         "manage_state" = true
  #       }
  #       "tfvars" = {
  #         "enabled" = true
  #       }
  #     }
  #   }
  # }

  _root_module_yaml_decoded = {
    for module in local.enabled_root_modules : module => {
      for yaml_file in fileset("${path.root}/${var.root_modules_path}/${module}/stacks", "*.yaml") :
      yaml_file => yamldecode(file("${path.root}/${var.root_modules_path}/${module}/stacks/${yaml_file}"))
    }
  }

  ## Common Stack configurations
  # Retrieve common Stack configurations for each root module
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

  ## Stack Configurations
  # Merge all Stack configurations from the root modules into a single map, and filter out the common config.
  # Example:
  # {
  #   "random-pet-example" = {
  #     "project_root" = "examples/complete/components/random-pet"
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
    for file, content in files : "${module}-${trimsuffix(file, ".yaml")}" =>
    merge(
      {
        "project_root"        = replace(format("%s/%s", var.root_modules_path, module), "../", "")
        "root_module"         = module,
        "terraform_workspace" = trimsuffix(file, ".yaml"),
      },
      content
    ) if file != var.common_config_file
    }
  ]...)

  # Get the configs for each stack, merged with the common configurations
  # Example:
  # {
  #   "random-pet-example" = {
  #     "project_root" = "examples/complete/components/random-pet"
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
      "folder:${local.configs[stack].root_module}/${local.configs[stack].terraform_workspace}"
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
    ]))
  }

  # Merge all before_init steps into a single map for each stack.
  before_init = {
    for stack in local.stacks : stack => compact(concat(
      var.before_init,
      try(local.stack_configs[stack].before_init, []),
      # This command is required for each stack.
      # It copies the tfvars file from the stack's workspace to the root module's directory
      # and renames it to `spacelift.auto.tfvars` to automatically load variable definitions for each run/task.
      ["cp tfvars/${local.configs[stack].terraform_workspace}.tfvars spacelift.auto.tfvars"],
    )) if try(local.configs[stack].tfvars.enabled, true)
  }
}

# Perform deep merge for common configurations and stack configurations
module "deep" {
  source   = "cloudposse/config/yaml//modules/deepmerge"
  version  = "1.0.2"
  for_each = local._root_module_stack_configs
  # Stack configuration will take precedence and overwrite the conflicting value from the common configuration (if any)
  maps = [local._common_configs[each.value.root_module], each.value]

  # To support merging labels from common.yaml, we need lists to append instead of overwrite
  append_list_enabled = true
}

resource "spacelift_stack" "default" {
  for_each = local.stacks

  administrative                   = coalesce(try(local.stack_configs[each.key].administrative, null), var.administrative)
  after_apply                      = compact(concat(try(local.stack_configs[each.key].after_apply, []), var.after_apply))
  after_destroy                    = compact(concat(try(local.stack_configs[each.key].after_destroy, []), var.after_destroy))
  after_init                       = compact(concat(try(local.stack_configs[each.key].after_init, []), var.after_init))
  after_perform                    = compact(concat(try(local.stack_configs[each.key].after_perform, []), var.after_perform))
  after_plan                       = compact(concat(try(local.stack_configs[each.key].after_plan, []), var.after_plan))
  autodeploy                       = coalesce(try(local.stack_configs[each.key].autodeploy, null), var.autodeploy)
  autoretry                        = try(local.stack_configs[each.key].autoretry, var.autoretry)
  before_apply                     = compact(coalesce(try(local.stack_configs[each.key].before_apply, []), var.before_apply))
  before_destroy                   = compact(coalesce(try(local.stack_configs[each.key].before_destroy, []), var.before_destroy))
  before_init                      = compact(coalesce(try(local.before_init[each.key], []), var.before_init))
  before_perform                   = compact(coalesce(try(local.stack_configs[each.key].before_perform, []), var.before_perform))
  before_plan                      = compact(coalesce(try(local.stack_configs[each.key].before_plan, []), var.before_plan))
  branch                           = try(local.stack_configs[each.key].branch, var.branch)
  description                      = coalesce(try(local.stack_configs[each.key].description, null), var.description)
  enable_local_preview             = try(local.stack_configs[each.key].enable_local_preview, var.enable_local_preview)
  enable_well_known_secret_masking = try(local.stack_configs[each.key].enable_well_known_secret_masking, var.enable_well_known_secret_masking)
  github_action_deploy             = try(local.stack_configs[each.key].github_action_deploy, var.github_action_deploy)
  labels                           = local.labels[each.key]
  manage_state                     = try(local.stack_configs[each.key].manage_state, var.manage_state)
  name                             = each.key
  project_root                     = local.configs[each.key].project_root
  protect_from_deletion            = try(local.stack_configs[each.key].protect_from_deletion, var.protect_from_deletion)
  repository                       = try(local.stack_configs[each.key].repository, var.repository)
  space_id                         = coalesce(try(local.stack_configs[each.key].space_id, null), var.space_id)
  terraform_smart_sanitization     = try(local.stack_configs[each.key].terraform_smart_sanitization, var.terraform_smart_sanitization)
  terraform_version                = try(local.stack_configs[each.key].terraform_version, var.terraform_version)
  terraform_workflow_tool          = var.terraform_workflow_tool
  terraform_workspace              = local.configs[each.key].terraform_workspace
  worker_pool_id                   = try(local.stack_configs[each.key].worker_pool_id, var.worker_pool_id)

  dynamic "github_enterprise" {
    for_each = var.github_enterprise != null ? [var.github_enterprise] : []
    content {
      namespace = github_enterprise.value["namespace"]
    }
  }
}

# The Spacelift Destructor is a feature designed to automatically clean up the resources no longer managed by our IaC.
# Don't toggle the creation/destruction of this resource with var.destructor_enabled,
# as it will delete all resources in the stack when toggled from 'true' to 'false'.
# Use the 'deactivated' attribute to disable the stack destructor functionality instead.
# https://github.com/spacelift-io/terraform-provider-spacelift/blob/master/spacelift/resource_stack_destructor.go
resource "spacelift_stack_destructor" "default" {
  for_each = local.stacks

  stack_id    = spacelift_stack.default[each.key].id
  deactivated = !try(local.stack_configs[each.key].destructor_enabled, var.destructor_enabled)

  # `depends_on` should be used to make sure that all necessary resources (environment variables, roles, integrations, etc.)
  # are still in place when the destruction run is executed.
  # See https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/stack_destructor
  depends_on = [
    spacelift_drift_detection.default,
    spacelift_aws_integration_attachment.default
  ]
}

resource "spacelift_aws_integration_attachment" "default" {
  for_each = {
    for stack, configs in local.stack_configs : stack => configs
    if try(configs.aws_integration_enabled, var.aws_integration_enabled)
  }
  integration_id = try(local.stack_configs[each.key].aws_integration_id, var.aws_integration_id)
  stack_id       = spacelift_stack.default[each.key].id
  read           = var.aws_integration_attachment_read
  write          = var.aws_integration_attachment_write
}

resource "spacelift_drift_detection" "default" {
  for_each = {
    for stack, configs in local.stack_configs : stack => configs
    if try(configs.drift_detection_enabled, var.drift_detection_enabled)
  }

  stack_id     = spacelift_stack.default[each.key].id
  ignore_state = try(local.stack_configs[each.key].drift_detection_ignore_state, var.drift_detection_ignore_state)
  reconcile    = try(local.stack_configs[each.key].drift_detection_reconcile, var.drift_detection_reconcile)
  schedule     = try(local.stack_configs[each.key].drift_detection_schedule, var.drift_detection_schedule)
  timezone     = try(local.stack_configs[each.key].drift_detection_timezone, var.drift_detection_timezone)

  lifecycle {
    precondition {
      condition     = alltrue([for schedule in try(local.stack_configs[each.key].drift_detection_schedule, var.drift_detection_schedule) : can(regex("^([0-9,\\-\\*]+\\s+){4}[0-9,\\-\\*]+$", schedule))])
      error_message = "Invalid cron schedule format for drift detection"
    }
  }
}
