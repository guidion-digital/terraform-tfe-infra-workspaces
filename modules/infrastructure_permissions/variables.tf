variable "name" {
  description = "Will be used for IAM policy, and user"
}

variable "workspace_policy" {
  description = "Policy to attach to the IAM user created by this module"
}

variable "workspace_id" {
  description = "Which workspace to populate with variables"
}

variable "aws_region" {
  description = "Region in which the secret can be found"
}
