variable "organization" {}
variable "networking_role" {}
variable "project" {}
variable "stage" {}
variable "parent_zone" {}
variable "workspace_policy" { default = null }
variable "remote_state_consumer_names" { default = [] }
variable "teams" {}

module "workspaces" {
  source = "../../"

  organization     = var.organization
  project          = var.project
  stage            = var.stage
  aws_region       = "eu-central-1"
  workspace_policy = var.workspace_policy
  teams            = var.teams

  applications = {
    "tfe-infra-workspaces-example" = {
      "app_type" = "api",
      # "application_policy"      = data.aws_iam_policy_document.webhooks_backend_default.json
      # "domain_account_role"     = local.guidion_io_role,
      # "github"                  = { repository = "example" },

      "service_types" = [
        "lambda"
      ],

      "supporting_services" = [
        "sqs",
        "dynamodb"
      ],

      "application_policy_arns" = [
        "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
      ],

      "application_role_arn_names" = [
        aws_iam_role.tfe_infra_workspaces_test.name,
      ],

      "application_role_arns" = [
        aws_iam_role.tfe_infra_workspaces_test.arn,
      ],

      "terraform_variables" = {
        "foo" = "bar",
      },

      # "terraform_hcl_variables" = {
      #   "api_keys_share" = "{ AWS = [\"arn:aws:iam::107947530158:role/sso/Superuser\"] }"
      # }
    },
  }

  # N.B. There is no value for this in any of the tests, and it's only here to
  # ensure all possible fields are shown
  remote_state_consumer_names = var.remote_state_consumer_names
}
