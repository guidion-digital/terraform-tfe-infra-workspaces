variable "organization" {}
variable "networking_role" {}
variable "project" {}
variable "stage" {}
variable "parent_zone" {}
variable "workspace_policy" { default = null }
variable "applications" { default = {} }
variable "remote_state_consumer_names" { default = [] }

module "workspaces" {
  source = "../../"

  organization     = var.organization
  project          = var.project
  stage            = var.stage
  aws_region       = "eu-central-1"
  applications     = var.applications
  workspace_policy = var.workspace_policy

  # N.B. There is no value for this in any of the tests, and it's only here to
  # ensure all possible fields are shown
  remote_state_consumer_names = var.remote_state_consumer_names
}
