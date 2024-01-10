# Global variables
variables {
  organization    = "guidion"
  networking_role = "arn:aws:iam::123456789012:role/workspaces/assumable-role-for-zones"
  project         = "constr"
  stage           = "dev"
  parent_zone     = "dev.constr.guidion.io"
}

# Application instance tests
#
run "application_workspaces" {
  module {
    source = "./"
  }

  command = plan

  variables {
    organization    = var.organization
    networking_role = var.networking_role
    project         = var.project
    stage           = var.stage
    parent_zone     = var.parent_zone

    # A few applications to demonstrate different ways of setting permissions
    applications = {
      "api-app-x" = {
        "app_type"            = "api",
        "service_types"       = ["lambda"],
        "domain_account_role" = var.networking_role,

        # This policy will be attached to the role created by this module, whose
        # name is in var.role_arn
        "application_policy_arns" = ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"],

        "terraform_variables" = {
          "parent_zone"         = var.parent_zone,
          "application_name"    = "api-app-x",
          "project"             = var.project,
          "domain_account_role" = var.networking_role,
          "stage"               = var.stage
        }
      },

      "api-app-y" = {
        "app_type"            = "api",
        "service_types"       = ["lambda"],
        "domain_account_role" = var.networking_role,

        # ARN is appended to the list of IAM roles the workspace user will be
        # permitted to pass to resources. Since the module did not create it,
        # you will need to pass it's name to your resources yourself (via a
        # Terraform variable, for example)
        #
        # For the sake of simplicity, we're specifying an AWS managed role here
        "application_role_arn_names" = ["GrafanaCloudWatchIntegration"],

        "terraform_variables" = {
          "parent_zone"         = var.parent_zone,
          "application_name"    = "api-app-y",
          "project"             = var.project,
          "domain_account_role" = var.networking_role,
          "stage"               = var.stage
        }
      }
    }

  }

  assert {
    condition = contains(keys(module.workspaces.workspaces), "${var.project}-${var.stage}-api-app-x")
    error_message = "An application workspace that should have been created, wasn't"
  }
}

# Infrastructure instance tests
#
run "without_existing_user_without_workspace_policy" {
  module {
    source = "./"
  }

  command = plan

  variables {
    organization    = var.organization
    networking_role = var.networking_role
    project         = var.project
    stage           = var.stage
    parent_zone     = var.parent_zone
  }

  assert {
    condition = module.workspaces.infrastructure_iam_user == {}
    error_message = "An IAM user was created for the infrastructure workspace, but shouldn't have been"
  }
}

run "without_existing_user_with_workspace_policy" {
  module {
    source = "./"
  }

  command = plan

  variables {
    organization     = var.organization
    networking_role  = var.networking_role
    project          = var.project
    stage            = var.stage
    parent_zone      = var.parent_zone
    workspace_policy = "arn:aws:iam::aws:policy/PowerUserAccess"
  }

  assert {
    condition = module.workspaces.infrastructure_iam_user != {}
    error_message = "An IAM user wasn't created for the infrastructure workspace, but should have been"
  }
}
