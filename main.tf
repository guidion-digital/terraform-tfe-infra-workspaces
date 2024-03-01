locals {
  application_workspaces    = length(var.applications) != 0 ? { for this_name, these_values in var.applications : "${var.project}-${var.stage}-${this_name}" => these_values } : {}
  infrastructure_workspaces = length(var.applications) == 0 ? { "${var.project}-${var.stage}" = "" } : {}
  workspaces                = merge(local.application_workspaces, local.infrastructure_workspaces)

  tags = concat([var.project], var.additional_tags, [var.stage], length(var.applications) != 0 ? ["application"] : ["infrastructure"])
}

# If this is an application workspace, we'll want to take advantage of TFC team tokens
resource "tfe_team" "this" {
  for_each = local.application_workspaces

  organization = var.organization
  name         = each.key
  visibility   = "organization"
}
resource "tfe_team_access" "this" {
  for_each = local.application_workspaces

  team_id      = tfe_team.this[each.key].id
  workspace_id = tfe_workspace.this[each.key].id

  permissions {
    runs              = "apply"
    variables         = "read"
    state_versions    = "read"
    sentinel_mocks    = "read"
    workspace_locking = false
    run_tasks         = true
  }
}
resource "tfe_team_token" "this" {
  for_each = local.application_workspaces

  team_id = tfe_team.this[each.key].id
}

resource "github_actions_environment_secret" "tfe_team_key" {
  for_each = { for k, v in local.application_workspaces : k => v if v.github != null }

  repository      = each.value.github.repository
  environment     = each.value.github.environment == null ? var.stage : each.value.github.environment
  secret_name     = "TFC_API_TOKEN"
  plaintext_value = tfe_team_token.this[each.key].token
}

# Fetch informtion (though only the workspace ID is used below) on workspaces
# specified in var.remote_state_consumer_names, so that we can share this
# workspace's data with them
data "tfe_workspace" "these" {
  for_each = toset(var.remote_state_consumer_names)

  name         = each.value
  organization = var.organization
}
locals {
  remote_state_consumer_ids = [for data in data.tfe_workspace.these : data.id]
}

resource "tfe_workspace" "this" {
  for_each = local.workspaces

  name                      = each.key
  working_directory         = try(each.value["working_directory"], null)
  description               = "Deploys for the ${each.key} item/environment in the ${var.project} project"
  organization              = var.organization
  remote_state_consumer_ids = local.remote_state_consumer_ids
  tag_names                 = local.tags

  # Oh gods I'm so sorry :(
  # - If this is an infrastructure workspace then:
  #   - Set the execution mode from var.workspace_execution_mode, or fallback to 'remote' if it's not set
  # - If this is an application workspaces then
  #   - If the application map has a workspace_execution_mode attribute, then use that value
  #   - If the application map does not have the attribute, then try to set it from var.workspace_execution_mode, or default to 'remote' if that has no value
  execution_mode = length(var.applications) == 0 ? try(var.workspace_execution_mode, "remote") : each.value["workspace_execution_mode"] != null ? each.value["workspace_execution_mode"] : try(var.workspace_execution_mode, "remote")
}

module "teams" {
  for_each = local.application_workspaces

  source = "./modules/team_access"

  organization = var.organization
  teams        = var.teams
  workspace_id = tfe_workspace.this[each.key].id
}

module "variables" {
  source   = "./modules/tfe_variables"
  for_each = var.applications

  terraform_variables             = merge(lookup(each.value, "terraform_variables", {}), { role_arn = module.permissions[each.key].application_iam_role_arn })
  terraform_hcl_variables         = lookup(each.value, "terraform_hcl_variables", {})
  environment_variables           = lookup(each.value, "environment_variables", {})
  sensitive_terraform_variables   = lookup(each.value, "sensitive_terraform_variables", {})
  sensitive_environment_variables = lookup(each.value, "sensitive_environment_variables", {})
  workspace_id                    = tfe_workspace.this["${var.project}-${var.stage}-${each.key}"].id
}

data "aws_caller_identity" "current" {}

# If this is an application workspace, get the workspace_policy and other permissions
# related attributes from the var.applications map
module "permissions" {
  source   = "./modules/application_permissions"
  for_each = var.applications

  name             = "${var.project}-${var.stage}-${each.key}"
  application_name = each.key
  # The following insanity is brought to you by the fact that optional fields in
  # complext objects can never be absent, but must be null
  workspace_policy           = each.value.workspace_policy == null ? null : each.value.workspace_policy
  application_policy         = each.value.application_policy == null ? null : each.value.application_policy
  application_policy_arns    = each.value.application_policy_arns == null ? [] : each.value.application_policy_arns
  application_role_arn_names = each.value.application_role_arn_names == null ? [] : each.value.application_role_arn_names
  service_types              = each.value.service_types == null ? [] : each.value.service_types
  supporting_services        = each.value.supporting_services == null ? [] : each.value.supporting_services
  domain_account_role        = each.value.domain_account_role == null ? null : each.value.domain_account_role
  project                    = var.project
  aws_region                 = "eu-central-1"
  workspace_id               = tfe_workspace.this["${var.project}-${var.stage}-${each.key}"].id

  cdn_app = each.value.app_type == "cdn" ? {
    bucket_name = "${var.project}-${var.stage}-${each.key}-origin"
  } : null

  api_app = each.value.app_type == "api" ? {
    event_arns = [
      "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/${each.key}-*"
    ],
    dynamodb_arns = [
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${each.key}*",
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${each.key}/stream/*"
    ],
    sqs_arns = [
      "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:${each.key}-*.fifo",
      "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:${each.key}-*-dlq.fifo",
      "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:${each.key}-*",
      "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:${each.key}*"
    ]
    sns_arns = [
      "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:${each.key}*"
    ]
    firewall_ipset_arns = [
      "arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:regional/ipset/${each.key}-regional-blocked/*",
      "arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:regional/ipset/${each.key}-regional-whitelist/*"
    ],
    ruleset_arns = [
      "arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:regional/webacl/${each.key}-regional-web-acl/",
      "arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:regional/webacl/${each.key}-regional-web-acl/*",
      "arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:regional/managedruleset/*/*"
    ]
  } : null

  container_app = each.value.app_type == "container" ? {
    targetgroup_arn           = "arn:aws:elasticloadbalancing:eu-central-1:${data.aws_caller_identity.current.account_id}:targetgroup/${each.key}/*",
    loadbalancer_listener_arn = "arn:aws:elasticloadbalancing:eu-central-1:${data.aws_caller_identity.current.account_id}:listener/net/${each.key}/*",
    ecs_cluster_arn           = "arn:aws:ecs:eu-central-1:${data.aws_caller_identity.current.account_id}:cluster/${each.key}",
    ecs_service_arn           = "arn:aws:ecs:eu-central-1:${data.aws_caller_identity.current.account_id}:service/*/${each.key}-service"
    loadbalancers = [
      "arn:aws:elasticloadbalancing:eu-central-1:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${each.key}/*",
      "arn:aws:elasticloadbalancing:eu-central-1:${data.aws_caller_identity.current.account_id}:loadbalancer/${each.key}",
      "arn:aws:elasticloadbalancing:eu-central-1:${data.aws_caller_identity.current.account_id}:loadbalancer/net/${each.key}/*"
    ],
  } : null
}

# If this is an infrastructure workspace and there's no existing IAM user, get
# the workspace_policy from var.workspace_policy, create a user, and attach it
# var.workspace_policy
#
# N.B. As well as the internal logic in locals for working out if we're creating
# an infrastructure workspace being true, var.workspace_policy must also be given
# in order for an IAM policy to be created
module "infrastructure_permissions" {
  for_each = var.workspace_policy != null ? local.infrastructure_workspaces : {}
  # for_each = { "foo" = "bar" }
  source = "./modules/infrastructure_permissions"

  name             = "${var.project}-${var.stage}"
  workspace_policy = var.workspace_policy
  aws_region       = "eu-central-1"
  workspace_id     = tfe_workspace.this["${var.project}-${var.stage}"].id
}

# If this is an infra workspace, it will have existing AWS credentials created
# for consumption written in the Secrets Manager. Pick those up and set them
# for the workspace to use. Credentials are otherwise created and set in
# module.infrastructure_permissions above
module "aws_secrets" {
  source = "./modules/aws_secrets_population"
  # If we're not given a policy, then create an IAM user
  for_each = var.workspace_policy == null ? local.infrastructure_workspaces : {}

  aws_region   = "eu-central-1"
  workspace_id = tfe_workspace.this[each.key].id
}

# FIXME: This doesn't work with an organisation token, but is supposed to work with a
#        team or owner token:
#        https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens#access-levels
#        It doesn't :/
#
# resource "tfe_notification_configuration" "slack" {
#   for_each = local.items
#
#   name             = "slack"
#   enabled          = true
#   destination_type = "slack"
#   triggers         = ["run:needs_attention", "run:completed", "run:errored"]
#   url              = var.slack_webhook_url
#   workspace_id     = each.value
# }
