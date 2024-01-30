variable "teams" {
  description = "Teams to give access to the application workspaces created"

  type = map(object({
    runs              = optional(string, "apply"),
    variables         = optional(string, "read"),
    state_versions    = optional(string, "read"),
    sentinel_mocks    = optional(string, "read"),
    workspace_locking = optional(bool, false),
    run_tasks         = optional(bool, true)
  }))
}

variable "workspace_id" {
  description = "Workspace to give access to"
  type        = string
}

variable "organization" {}
