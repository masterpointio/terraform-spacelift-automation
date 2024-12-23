variable "branch" {
  type        = string
  description = "Specify which branch to use within the infrastructure repository."
  default     = "main"
}

variable "all_root_modules_enabled" {
  type        = bool
  description = "When set to true, all subdirectories in root_modules_path will be treated as root modules."
  default     = false
}

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

variable "root_modules_path" {
  type        = string
  description = "The path, relative to the root of the repository, where the root module can be found."
  default     = "root-modules"
}
