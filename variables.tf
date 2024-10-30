# GitHub
variable "github_enterprise" {
  type = object({
    namespace = string
    id        = optional(string)
  })
  description = "The GitHub VCS settings"
}

variable "repository" {
  type        = string
  description = "The name of your infrastructure repo"
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
    Ignored when enable_all_root_modules is true.
    Example: ["spacelift-automation", "k8s-cluster"]
    EOT
  default     = []
}

variable "enable_all_root_modules" {
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
variable "aws_integration_id" {
  type        = string
  description = "ID of the AWS integration to attach."
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

variable "description" {
  type        = string
  description = "Description of the stack"
  default     = "Managed by spacelift-automation Terraform root module."
}

variable "destructor_enabled" {
  type        = bool
  description = "Flag to enable/disable the destructor for the Stack."
  default     = false
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
  description = "Place the stack in the specified space_id."
  default     = "root"
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
  description = "Terraform version to use."
  default     = "1.7.2"
}

variable "worker_pool_id" {
  type        = string
  description = <<-EOT
  ID of the worker pool to use.
  NOTE: worker_pool_id is required when using a self-hosted instance of Spacelift.
  EOT
  default     = null
}
