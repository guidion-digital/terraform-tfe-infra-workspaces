variable "name" {
  description = "Will be used for IAM policy and role"
}

variable "workspace_policy" {
  description = "Policy to attach to the IAM role created by this module"
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
