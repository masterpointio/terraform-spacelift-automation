# This Terraform code automates the creation and management of Spacelift stacks based on the structure
# and configurations defined in the Git repository, default Stack values and additional input variables.
# It primarily relies on dynamic local expressions to generate configurations based on the
# input variables and Git structure so it can be consumed by Spacelift resources.
# This module can also manage the automation stack intself, but it should be bootsrapped manually.
#
# It handles the following:
# 1. Workspaces (see ## Workspaces)
# Reads workspace names for each root module set in the root_modules variable in the spacelift-automation
# Workspace names are extracted from the files in each root module `tfvars` directory, and are equal to the file names.
# Stacks names are build from the root module name and workspace name.
#
# 2. Stack Configurations from Git (see ## Stack Configurations from Git)
# Reads the Spacelift stack configurations strictly based on the root modules structure in Git and file names.
# These are the configurations required to be set for a stack, e.g. project_root, terraform_workspace, root_module.
#
# 3. Stack Configurations from Terraform variables (see ## Stack Configurations from Terraform variables)
# Reads the Spacelift stack configurations explicitly specified in the spacelift-automation tfvars file.
# These configurations are intended to override the default values.
#
# 4. Common Stack configrations
# Some configurations are euqal across the whole root module, and can be set it on a root module level:
# * Space IDs: in the majority if cases all the workspaces in a root module belong to the same Spacelift space, so
# we allow setting a "global" space_id for all stacks on a root module level.
# * Autodeploy: if all the stacks in a root module should be autodeployed.
# * Administrative: if all the stacks in a root module are administrative, e.g stacks that manage Spacelift resources.
#
# 5. Dependencies (see ## Dependencies)
# Builds stack dependencies based on the root modules configuration.
# Our main case is to support the dependency from each child from its parent stack, which is spacelift-automation-<workspace>.
#
# 6. Labels (see ## Labels)
# Generates labels for the stacks based on administrative, dependency, and folder information.
#
# Syntax note:
# The local expression started with an underscore `_` is used to store intermediate values
# that are not directly used in the resource creation.

locals {
  enabled          = module.this.enabled
  aws_role_enabled = local.enabled && var.aws_role_enabled

  ## Workspaces
  # Extracts the list of workspace names from tfvars files for each given root module.
  # Root module name is used as a key of the map.
  # For root_modules = {
  #   "client-infra" = {},
  #   "spacelift-automation" = {
  #     stacks = {
  #       mp-automation = {
  #         administrative = true
  #         description    = "Administrative Spacelift Stack for managing Masterpoint's Infrastructure."
  #       }
  #     }
  #   }
  # }
  # If the tfvars directory for `client-infra` contains files "client1.tfvars" and "client2.tfvars",
  # and for `spacelift-automation` it contains "mp-automation.tfvars":
  # The resulting workspaces will be:
  # {
  #   "client-infra" = [
  #     "client1",
  #     "client2",
  #   ]
  #   "spacelift-automation" = [
  #     "mp-automation",
  #   ]
  # }

  _workspaces = {
    for key in keys(var.root_modules) : key => [
      for file in fileset(format("../../%s/%s/tfvars/", var.root_modules_path, key), "*.tfvars") :
      trimsuffix(file, ".tfvars")
    ]
  }

  ## Stack Configurations from Git
  # Creates a map of the Git based stack configurations for each root module.
  # Example for workspaces `client1` and `client2` in `client-infra` root module:
  # {
  #   "client-infra" = {
  #     "client-infra-client1" = {
  #       "terraform_workspace" = "client1"
  #       "project_root"        = "root-modules/client-infra"
  #       "root_module"         = "client-infra"
  #     }
  #     "client-infra-client2" = {
  #       "terraform_workspace" = "client2"
  #       "project_root"        = "root-modules/client-infra"
  #       "root_module"         = "client-infra"
  #     }
  #   }
  # }

  _git_stack_configs = {
    for module, workspaces in local._workspaces : module => {
      for workspace in workspaces : "${module}-${workspace}" =>
      {
        terraform_workspace = workspace,
        project_root        = format("%s/%s", var.root_modules_path, module)
        root_module         = module
      }
    }
  }

  # Flatten the stack configurations based into a single map.
  # Example for the `client-infra` root module:
  # {
  #   "client-infra-client1" = {
  #     "terraform_workspace" = "client1"
  #     "project_root"        = "root-modules/client-infra"
  #     "root_module"         = "client-infra"
  #   }
  #   "client-infra-client2" = {
  #     "terraform_workspace" = "client2"
  #     "project_root"        = "root-modules/client-infra"
  #     "root_module"         = "client-infra"
  #   }
  # }

  _flat_git_stack_configs = merge([
    for module, stacks in local._git_stack_configs : {
      for stack_name, stack in stacks : stack_name => stack
    }
  ]...)

  ## Stack Configurations from Terraform variables
  # Creates a map of the stack configurations that should be created for each root module specified in
  # the spacelift-automation tfvars file.
  # Example for workspaces `trigger-automated-retries` and `trigger-dependencies` in `spacelift-policies` root module:
  # {
  #   "spacelift-policies" = {
  #     "spacelift-policies-trigger-automated-retries" = {
  #       "administrative" = true
  #     }
  #     "spacelift-policies-trigger-dependencies" = {
  #       "administrative" = true
  #       "description" = "Policy to trigger other stacks."
  #   }
  # }

  _tfvars_stack_configs = {
    for module_name, configs in var.root_modules : module_name => {
      for workspace_name, workspace_configs in coalesce(configs.stacks, {}) : "${module_name}-${workspace_name}" => workspace_configs
    }
  }

  # Flatten the configured stacks into a single map and merge with the common stack configurations.
  # Example for the `spacelift-policies` root module:
  # {
  #   "spacelift-policies-trigger-automated-retries" = {
  #     "administrative" = true
  #   }
  #   "spacelift-policies-trigger-dependencies" = {
  #     "administrative" = true
  #     "description" = "Policy to trigger other stacks."
  #   }
  # }

  _flat_tfvars_stack_configs = merge([
    for module, stack in local._tfvars_stack_configs : {
      for stack_name, stack_config in stack : stack_name => stack_config
    }
  ]...)

  _common_stack_configs = {
    for module, stacks in local._git_stack_configs : module => {
      for stack_name, stack in stacks : stack_name => try(var.root_modules[module].common_stack_configs, {})
    }
  }

  _flat_common_stack_configs = merge([
    for module, stack in local._common_stack_configs : {
      for stack_name, stack_config in stack : stack_name => stack_config
    }
  ]...)

  # Iterate over stack configs in git and merge all stack configurations from tfvars into a single map.
  # stack_configs = {
  #   for k, v in local._flat_git_stack_configs : k => merge(
  #     v,
  #     try(local._flat_common_stack_configs[k], {}),
  #     try(local._flat_tfvars_stack_configs[k], {}),
  #   )
  # }

  # Get the list of all stack names
  #stacks = toset(keys(local.stack_configs))
  stacks = toset(keys(local.stack_configs))

  ## Dependencies

  # Get the dependencies from the root modules configuration.
  # Expected to be set on a per-module. Might want to revisit this in the future.
  # Child stacks always depend on the spacelift-automation stack.
  # Example for the `client-infra` root module:
  # {
  #   "client-infra" = {
  #     "depends_on_stack_ids" = tolist([
  #       "spacelift-automation-mp-main",
  #       "spacelift-webhooks-slack-notifications",
  #     ])
  #   }
  # }

  _module_depends_on_stack_ids = {
    for module_name, module in var.root_modules : module_name => {
      depends_on_stack_ids = [format("%s-%s", "spacelift-automation", terraform.workspace)]
    }
  }
  # Creates a map of the dependencies list based for each stack.
  # Example for the `client-infra` root module:
  # {
  #   "client-infra-client1" = {
  #     depends_on_stack_ids = ["spacelift-automation-mp-main", "spacelift-webhooks-slack-notifications"]
  #   }
  #   "client-infra-client2" = {
  #     depends_on_stack_ids = ["spacelift-automation-mp-main", "spacelift-webhooks-slack-notifications"]
  #   }
  # }

  _depends_on_stack_ids = merge([
    for module, stacks in local._git_stack_configs : {
      for stack_name, stack in stacks : stack_name => {
        depends_on_stack_ids = concat(
          values(lookup(local._module_depends_on_stack_ids, module, [])),
          try(local.stack_configs[stacks.stack_name].depends_on_stack_ids, [])
        )
      }
    }
  ]...)

  # Break dependencies into a flat list.
  # Example for the `client-infra` root module:
  # [
  #   {
  #     stack_id            = "client-infra-client1"
  #     depends_on_stack_id = "spacelift-automation-mp-main"
  #   },
  #   {
  #     stack_id            = "client-infra-client1"
  #     depends_on_stack_id = "spacelift-webhooks-slack-notifications"
  #   },
  #   {
  #     stack_id            = "client-infra-client2"
  #     depends_on_stack_id = "spacelift-automation-mp-main"
  #   },
  #   {
  #     stack_id            = "client-infra-client2"
  #     depends_on_stack_id = "spacelift-webhooks-slack-notifications"
  #   }
  # ]

  _dependency_list = flatten([
    for stack_name, config in local._depends_on_stack_ids : [
      for depends_on in config.depends_on_stack_ids : [
        for id in depends_on : {
          stack_id            = stack_name
          depends_on_stack_id = id
        }
      ]
    ]
  ])

  ## Labels
  # Сreates a map of administrative labels for each stack that has the administrative property set to true.
  # Example:
  # {
  #   "spacelift-automation-mp-main" = [
  #     "administrative",
  #   ]
  #   "spacelift-policies-notify-stack-creation" = [
  #     "administrative",
  #   ]
  #   "spacelift-policies-notify-tf-completed" = [
  #     "administrative",
  #   ]
  # }

  _administrative_labels = {
    # Normalizing the value here is required due to TF not enforcing
    # strict type-checking for `stacks = optional(any)` in var.root_modules
    for stack_name, stack in local.stack_configs : stack_name => ["administrative"] if tobool(try(stack.administrative, false)) == true
  }

  # Creates a map of `depends-on` labels for each stack based on the root module level dependency configuration.
  # Example:
  # {
  #   "spacelift-spaces-clients" = [
  #     "depends-on:spacelift-automation-mp-main",
  #   ]
  #   "spacelift-webhooks-notify-tf-completed" = [
  #     "depends-on:spacelift-automation-mp-main",
  #   ]
  # }

  _dependency_labels = {
    for dependency in local._dependency_list :
    dependency.stack_id => [
      "depends-on:${dependency.depends_on_stack_id}"
    ]
  }

  # Creates a map of folder labels for each stack based on Git structure for a proper grouping stacks in Spacelift UI.
  # https://docs.spacelift.io/concepts/stack/organizing-stacks#label-based-folders
  # Example:
  # {
  #   "spacelift-spaces-clients" = [
  #     "folder:spacelift-spaces/clients",
  #   ]
  #   "spacelift-spaces-prod" = [
  #     "folder:spacelift-spaces/prod",
  #   ]
  #   "spacelift-webhooks-notify-tf-completed" = [
  #     "folder:spacelift-webhooks/notify-tf-completed",
  #   ]
  # }

  _folder_labels = merge([
    for module, stacks in local._git_stack_configs : {
      for stack_name, stack in stacks : stack_name => [
        "folder:${stack.root_module}/${stack.terraform_workspace}"
      ]
    }
  ]...)

  # Merge all labels into a single map for each stack.
  # Example:
  # {
  #   "spacelift-spaces-clients" = [
  #     "folder:spacelift-spaces/clients",
  #     "depends-on:spacelift-automation-mp-main",
  #   ]
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
    )) if local.configs[stack].tfvars.enabled
  }
}

resource "spacelift_stack" "this" {
  for_each = local.enabled ? local.stacks : toset([])

  space_id                     = coalesce(try(local.stack_configs[each.key].space_id, null), var.space_id)
  name                         = each.key
  administrative               = coalesce(try(local.stack_configs[each.key].administrative, null), var.administrative)
  after_apply                  = compact(concat(try(local.stack_configs[each.key].after_apply, []), var.after_apply))
  after_destroy                = compact(concat(try(local.stack_configs[each.key].after_destroy, []), var.after_destroy))
  after_init                   = compact(concat(try(local.stack_configs[each.key].after_init, []), var.after_init))
  after_perform                = compact(concat(try(local.stack_configs[each.key].after_perform, []), var.after_perform))
  after_plan                   = compact(concat(try(local.stack_configs[each.key].after_plan, []), var.after_plan))
  autodeploy                   = coalesce(try(local.stack_configs[each.key].autodeploy, null), var.autodeploy)
  autoretry                    = try(local.stack_configs[each.key].autoretry, var.autoretry)
  before_apply                 = compact(coalesce(try(local.stack_configs[each.key].before_apply, []), var.before_apply))
  before_destroy               = compact(coalesce(try(local.stack_configs[each.key].before_destroy, []), var.before_destroy))
  before_init                  = compact(coalesce(try(local.before_init[each.key], []), var.before_init))
  before_perform               = compact(coalesce(try(local.stack_configs[each.key].before_perform, []), var.before_perform))
  before_plan                  = compact(coalesce(try(local.stack_configs[each.key].before_plan, []), var.before_plan))
  description                  = coalesce(try(local.stack_configs[each.key].description, null), var.description)
  repository                   = try(local.stack_configs[each.key].repository, var.repository)
  branch                       = try(local.stack_configs[each.key].branch, var.branch)
  project_root                 = local.configs[each.key].project_root
  manage_state                 = try(local.stack_configs[each.key].manage_state, var.manage_state)
  labels                       = local.labels[each.key]
  enable_local_preview         = try(local.stack_configs[each.key].enable_local_preview, var.enable_local_preview)
  terraform_smart_sanitization = try(local.stack_configs[each.key].terraform_smart_sanitization, var.terraform_smart_sanitization)
  terraform_version            = try(local.stack_configs[each.key].terraform_version, var.terraform_version)
  terraform_workflow_tool      = var.terraform_workflow_tool
  terraform_workspace          = local.configs[each.key].terraform_workspace

  protect_from_deletion = try(local.stack_configs[each.key].protect_from_deletion, var.protect_from_deletion)

  worker_pool_id = try(local.stack_configs[each.key].worker_pool_id, var.worker_pool_id)

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
resource "spacelift_stack_destructor" "this" {
  for_each = local.enabled ? local.stacks : toset([])

  stack_id    = spacelift_stack.this[each.key].id
  deactivated = !try(local.stack_configs[each.key].destructor_enabled, var.destructor_enabled)

  depends_on = [
    spacelift_drift_detection.this,
    spacelift_aws_integration_attachment.this
  ]
}

# resource "spacelift_aws_role" "this" {
#   for_each = local.aws_role_enabled ? local.stacks : toset([])

#   stack_id = spacelift_stack.this[each.key].id
#   role_arn = var.aws_role_arn
# }

resource "spacelift_aws_integration_attachment" "this" {
  for_each = local.aws_role_enabled ? local.stacks : toset([])
  integration_id = try(local.stack_configs[each.key].aws_integration_id, var.aws_integration_id)
  stack_id       = spacelift_stack.this[each.key].id
  read           = var.aws_integration_attachment_read
  write          = var.aws_integration_attachment_write
}

resource "spacelift_drift_detection" "this" {
  for_each = local.enabled ? {
    for key, value in local.stacks : key => value
    if try(local.stack_configs[key].drift_detection_enabled, var.drift_detection_enabled)
  } : {}

  stack_id     = spacelift_stack.this[each.key].id
  ignore_state = try(local.stack_configs[each.key].drift_detection_ignore_state, var.drift_detection_ignore_state)
  reconcile    = try(local.stack_configs[each.key].drift_detection_reconcile, var.drift_detection_reconcile)
  schedule     = try(local.stack_configs[each.key].drift_detection_schedule, var.drift_detection_schedule)
  timezone     = try(local.stack_configs[each.key].drift_detection_timezone, var.drift_detection_timezone)
}
