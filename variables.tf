variable "organization" {
  description = "TFE organization name"
}

variable "project" {
  description = "Can be thought of as the Organisational Unit. Used for naming and tagging. It is _not_ the application name"
}

variable "workspace_execution_mode" {
  description = "Whether to run Terraform on TFC or on your machine. Used only for infrastructure workspaces"
  default     = null
  type        = string
}

variable "workspace_policy" {
  description = "Attached to the created workspace IAM user. Used only for infrastrucutre workspaces"
  default     = null
  type        = string
}

variable "applications" {
  description = <<-EOT
    applications = {
      app_type                        = "Used to work out permissions for _workspace_ role"
      github                          = "Will write Github Actions environment secret and variable for use with TFC. See type definition for object fields"
      working_directory               = "Directory to change into before executing. Useful for examples inside the module's own repo"
      workspace_settings = Optional object of {
        auto_apply                    = "Apply after successful plan?"
        structured_run_output_enabled = "New style output in TFC?"
        ssh_key_id                    = "Key ID that can access the workspace"
        terraform_version             = "Version of Terraform to run in the workspace"
        trigger_patterns              = "Patterns that will trigger runs on changes"
        trigger_prefixes              = "Prefixes that will trigger runs on changes"
        working_directory             = "Directory to change into before executing. Useful for examples inside the module's own repo"
        execution_mode                = "'remote' or 'local', defaults to remote"
      }
      workspace_policy                = "Will be added to the workspace role"
      workspace_execution_mode        = "'remote' or 'local', defaults to remote"
      domain_account_role             = "Role which gives permissions to edit the Route53 zone the application uses"
      application_policy              = "Added to the application role"
      application_policy_arns         = "Added to the application role"
      application_role_arn_names      = "Will be added to the list of allowed roles for the application"
      service_types                   = "AWS services which may use the application role"
      supporting_services             = "AWS services the application can have permissions for"
      terraform_variables             = "Map of (Terraform) string variables to give the workspace"
      terraform_hcl_variables         = "Map of (Terraform) strings containing HCL variable"
      environment_variables           = "Map of environment variables to be used at runtime"
      sensitive_terraform_variables   = "Map of (Terraform) string variables to give the workspace, which are to be marked as sensitive"
      sensitive_environment_variables = "Map of environment variables to be used at runtime, which are to be marked as sensitive"
    }
  EOT

  type = map(object({
    app_type = optional(string, null),
    github = optional(object({
      repository  = string,
      environment = optional(string, null)
    }), null),
    working_directory        = optional(string, null),
    workspace_execution_mode = optional(string),
    # TODO: The above two fields are deprecated since we now have them in this
    # workspace_settings block, but we need a breaking change to remove them
    workspace_settings = optional(object({
      auto_apply                    = optional(bool, null),
      structured_run_output_enabled = optional(bool, null),
      ssh_key_id                    = optional(string, null),
      terraform_version             = optional(string, null),
      trigger_patterns              = optional(list(string), null),
      trigger_prefixes              = optional(list(string), null),
      working_directory             = optional(string, null),
      execution_mode                = optional(string, null),
    }), {})
    workspace_policy                = optional(string, null),
    domain_account_role             = optional(string, null),
    application_policy              = optional(string, ""),
    application_policy_arns         = optional(list(string), []),
    application_role_arn_names      = optional(list(string), []),
    service_types                   = optional(list(string), []),
    supporting_services             = optional(list(string), []),
    terraform_variables             = optional(map(string), {}),
    terraform_hcl_variables         = optional(map(string), {}),
    environment_variables           = optional(map(string), {}),
    sensitive_terraform_variables   = optional(map(string), {})
    sensitive_environment_variables = optional(map(string), {})
  }))

  default = {}
}

variable "stage" {
  description = "Optional (AWS) stage application will be deployed in"
}

variable "additional_tags" {
  description = "Will be added to var.project for additional tagging"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "Where we'll be deploying to"
}

variable "slack_webhook_url" {
  description = "Used for notifications"
  default     = "UNUSED FOR NOW"
}

variable "remote_state_consumer_names" {
  description = "List of workspace names to share state of this workspace with"
  default     = []
}

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

  default = {}
}
