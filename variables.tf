variable "root_module_structure" {
  type        = string
  description = <<-EOT
  The root module structure of the Stacks that you're reading in. See README for full details.

  MultiInstance - You're using Workspaces or Dynamic Backend configuration to create multiple instances of the same root module code.
  SingleInstance - You're using copies of a root module and your directory structure to create multiple instances of the same Terraform code.
  EOT
  default     = "MultiInstance"

  validation {
    condition     = contains(["MultiInstance", "SingleInstance"], var.root_module_structure)
    error_message = "Valid values for root_module_structure are (MultiInstance, SingleInstance)."
  }
}

variable "runtime_overrides" {
  type        = any
  description = <<EOT
  Runtime overrides that are merged into the stack config.
  This allows for per-root-module overrides of the stack resources at runtime
  so you have more flexibility beyond the variable defaults and the static stack config files.
  Keys are the root module names and values match the StackConfig schema.
  See `stack-config.schema.json` for full details on the schema and
  `tests/fixtures/multi-instance/root-module-a/stacks/default-example.yaml` for a complete example.
  EOT
  default     = {}
}

variable "github_enterprise" {
  type = object({
    namespace = string
    id        = optional(string)
  })
  description = "The GitHub VCS settings"
  default     = null
}

variable "azure_devops" {
  type = object({
    project = string
    id      = optional(string)
  })
  description = "The Azure DevOps integration settings"
  default     = null
}

variable "raw_git" {
  type = object({
    namespace = string
    url       = string
  })
  description = "The raw Git integration settings"
  default     = null
}

variable "gitlab" {
  type = object({
    namespace = string
    id        = optional(string)
  })
  description = "The GitLab integration settings"
  default     = null
}

variable "bitbucket_cloud" {
  type = object({
    namespace = string
    id        = optional(string)
  })
  description = "The Bitbucket Cloud integration settings"
  default     = null
}

variable "bitbucket_datacenter" {
  type = object({
    namespace = string
    id        = optional(string)
  })
  description = "The Bitbucket Data Center integration settings"
  default     = null
}


variable "repository" {
  type        = string
  description = "The name of your infrastructure repo"
}

variable "runner_image" {
  type        = string
  description = "URL of the Docker image used to process Runs. Defaults to `null` which is Spacelift's standard (Alpine) runner image."
  default     = null
}

variable "branch" {
  type        = string
  description = "Specify which branch to use within the infrastructure repository."
  default     = "main"
}

variable "root_modules_path" {
  type        = string
  description = "The path, relative to the root of the repository, where the root module can be found."
  default     = "root-modules"
}

variable "enabled_root_modules" {
  type        = list(string)
  description = <<-EOT
    List of root modules where to look for stack config files.
    Ignored when all_root_modules_enabled is true.
    Example: ["spacelift-automation", "k8s-cluster"]
    EOT
  default     = []
}

variable "all_root_modules_enabled" {
  type        = bool
  description = "When set to true, all subdirectories in root_modules_path will be treated as root modules."
  default     = false
}

# Spacelift Backend
variable "terraform_workflow_tool" {
  type        = string
  description = <<-EOT
  Defines the tool that will be used to execute the workflow.
  This can be one of OPEN_TOFU, TERRAFORM_FOSS or CUSTOM.
  EOT
  default     = "OPEN_TOFU"

  validation {
    condition     = contains(["OPEN_TOFU", "TERRAFORM_FOSS", "CUSTOM"], var.terraform_workflow_tool)
    error_message = "Valid values for terraform_workflow_tool are (OPEN_TOFU, TERRAFORM_FOSS, CUSTOM)."
  }
}

# Stack Cloud Integrations
variable "aws_integration_enabled" {
  type        = bool
  description = "Indicates whether the AWS integration is enabled."
  default     = false
}

variable "aws_integration_id" {
  type        = string
  description = "ID of the AWS integration to attach."
  default     = null
}

variable "aws_integration_name" {
  type        = string
  description = "Name of the AWS integration to attach, which will be resolved to aws_integration_id. We recommend using names rather than IDs to improve clarity & readability. Since Spacelift enforces unique names, you can rely on names as identifiers without worrying about duplication issues."
  default     = null
}

variable "aws_integration_attachment_read" {
  type        = bool
  description = "Indicates whether this attachment is used for read operations."
  default     = true
}

variable "aws_integration_attachment_write" {
  type        = bool
  description = "Indicates whether this attachment is used for write operations."
  default     = true
}

# Configuration for the Spacelift Stack
variable "common_config_file" {
  type        = string
  description = "Name of the common configuration file for the stack across a root module."
  default     = "common.yaml"
}
# Default Stack Configuration
variable "administrative" {
  type        = bool
  description = "Flag to mark the stack as administrative"
  default     = false
}

variable "additional_project_globs" {
  type        = set(string)
  description = "Project globs is an optional list of paths to track stack changes of outside of the project root. Push policies are another alternative to track changes in additional paths."
  default     = []
}

variable "after_apply" {
  type        = list(string)
  description = "List of after-apply scripts"
  default     = []
}

variable "after_destroy" {
  type        = list(string)
  description = "List of after-destroy scripts"
  default     = []
}

variable "after_init" {
  type        = list(string)
  description = "List of after-init scripts"
  default     = []
}

variable "after_perform" {
  type        = list(string)
  description = "List of after-perform scripts"
  default     = []
}

variable "after_plan" {
  type        = list(string)
  description = "List of after-plan scripts"
  default     = []
}

variable "after_run" {
  type        = list(string)
  description = "List of after-run (aka `finally` hook) scripts"
  default     = []
}

variable "autodeploy" {
  type        = bool
  description = "Flag to enable/disable automatic deployment of the stack"
  default     = true
}

variable "autoretry" {
  type        = bool
  description = "Flag to enable/disable automatic retry of the stack"
  default     = false
}

variable "before_apply" {
  type        = list(string)
  description = "List of before-apply scripts"
  default     = []
}

variable "before_destroy" {
  type        = list(string)
  description = "List of before-destroy scripts"
  default     = []
}

variable "before_init" {
  type        = list(string)
  description = "List of before-init scripts"
  default     = []
}

variable "before_perform" {
  type        = list(string)
  description = "List of before-perform scripts"
  default     = []
}

variable "before_plan" {
  type        = list(string)
  description = "List of before-plan scripts"
  default     = []
}

variable "default_tf_workspace_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
  Enables the use of `default` Terraform workspace instead of managing multiple workspaces within a root module.

  NOTE: We encourage the use of Terraform workspaces to manage multiple environments.
  However, you will want to disable this behavior if you're utilizing different backends for each instance
  of your root modules (we call this "Dynamic Backends").
  EOT
}

variable "description" {
  type        = string
  description = <<EOT
    A description for the created Stacks. This is a template string that will be rendered with the final config object for the stack.
    See the main.tf for full internals of that object and the documentation on templatestring for usage.
    https://opentofu.org/docs/language/functions/templatestring/
  EOT
  default     = "Root Module: $${root_module}\nProject Root: $${project_root}\nWorkspace: $${terraform_workspace}\nManaged by spacelift-automation Terraform root module."
}

variable "destructor_enabled" {
  type        = bool
  description = "Whether to enable the stack destructor by default"
  default     = true
}

variable "destructor_deactivated" {
  type        = bool
  description = "Whether to deactivate the stack destructor by default"
  default     = true

  validation {
    condition     = !(var.destructor_deactivated && !var.destructor_enabled)
    error_message = "destructor_deactivated cannot be true when destructor_enabled is false"
  }
}

variable "drift_detection_enabled" {
  type        = bool
  description = "Flag to enable/disable Drift Detection configuration for a Stack."
  default     = false
}

variable "drift_detection_ignore_state" {
  type        = bool
  description = <<-EOT
  Controls whether drift detection should be performed on a stack
  in any final state instead of just 'Finished'.
  EOT
  default     = false
}

variable "drift_detection_reconcile" {
  type        = bool
  description = "Flag to enable/disable automatic reconciliation of drifts."
  default     = false
}

variable "drift_detection_schedule" {
  type        = list(string)
  description = "The schedule for drift detection."
  default     = ["0 4 * * *"]
}

variable "drift_detection_timezone" {
  type        = string
  description = "The timezone for drift detection."
  default     = "UTC"
}

variable "enable_local_preview" {
  type        = bool
  description = "Indicates whether local preview runs can be triggered on this Stack."
  default     = false
}

variable "enable_well_known_secret_masking" {
  type        = bool
  description = "Indicates whether well-known secret masking is enabled."
  default     = true
}

variable "github_action_deploy" {
  type        = bool
  description = "Indicates whether GitHub users can deploy from the Checks API."
  default     = true
}

variable "labels" {
  type        = list(string)
  description = "List of labels to apply to the stacks."
  default     = []
}

variable "manage_state" {
  type        = bool
  description = "Determines if Spacelift should manage state for this stack."
  default     = false
}

variable "protect_from_deletion" {
  type        = bool
  description = "Protect this stack from accidental deletion. If set, attempts to delete this stack will fail."
  default     = false
}

variable "space_id" {
  type        = string
  description = "Place the created stacks in the specified space_id. Mutually exclusive with space_name."
  default     = null
}

variable "space_name" {
  type        = string
  description = "Place the created stacks in the specified space_name. Mutually exclusive with space_id. We recommend using names rather than IDs to improve clarity & readability. Since Spacelift enforces unique names, you can rely on names as identifiers without worrying about duplication issues."
  default     = null
}

variable "terraform_smart_sanitization" {
  type        = bool
  description = <<-EOT
  Indicates whether runs on this will use terraform's sensitive value system to sanitize
  the outputs of Terraform state and plans in spacelift instead of sanitizing all fields.
  EOT
  default     = false
}

variable "terraform_version" {
  type        = string
  description = "OpenTofu/Terraform version to use. Defaults to the latest available version of the `terraform_workflow_tool`."
  default     = null
}

variable "worker_pool_id" {
  type        = string
  description = <<-EOT
  ID of the worker pool to use. Mutually exclusive with worker_pool_name.
  NOTE: worker_pool_name or worker_pool_id is required when using a self-hosted instance of Spacelift.
  We recommend using names rather than IDs to improve clarity & readability. Since Spacelift enforces unique names, you can rely on names as identifiers without worrying about duplication issues.
  EOT
  default     = null
}

variable "worker_pool_name" {
  type        = string
  description = <<-EOT
  Name of the worker pool to use. Mutually exclusive with worker_pool_id.
  NOTE: worker_pool_name or worker_pool_id is required when using a self-hosted instance of Spacelift.
  EOT
  default     = null
}

variable "spaces" {
  description = "A map of Spacelift Spaces to create"
  type = map(object({
    description      = optional(string, null)
    inherit_entities = optional(bool, false)
    labels           = optional(list(string), null)
    parent_space_id  = optional(string, "root")
  }))
  default = {}
}
