variable "name" {
  description = "Will be used for IAM policy and user/role"
}

variable "workspace_policy" {
  description = "Policy to attach to the IAM user/role created by this module"
}

variable "use_oidc" {
  description = "Use OIDC-based AWS auth (role) instead of static IAM user credentials"
  type        = bool
  default     = false
}

variable "workspace_id" {
  description = "Which workspace to populate with variables"
}

variable "aws_region" {
  description = "AWS region for the workspace"
}

variable "organization" {
  description = "Terraform Cloud organization name used in OIDC trust conditions"
  type        = string
}
