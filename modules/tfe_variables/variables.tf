variable "terraform_variables" {
  description = "Additional Terraform variables to add to the workspace"
  type        = map(string)
  default     = {}
}

variable "terraform_hcl_variables" {
  description = "Additional Terraform variables to add to the workspace that need be treated like TF code"
  type        = map(string)
  default     = {}
}

variable "environment_variables" {
  description = "Additional environment variables to add to the workspace"
  type        = map(string)
  default     = {}
}

variable "sensitive_terraform_variables" {
  description = "Additional Terraform variables to add to the workspace"
  type        = map(string)
  default     = {}
}

variable "sensitive_environment_variables" {
  description = "Additional sensitive environment variables to add to the workspace"
  type        = map(string)
  default     = {}
}

variable "workspace_id" {
  description = "TFC workspace ID"
  type        = string
}
