output "application_iam_role_arns" {
  value = { for k, v in module.permissions : k => v.application_iam_role_arn }
}

output "workspace_ids" {
  value = { for this_workspace, these_values in tfe_workspace.this : this_workspace => these_values.id }
}

output "infrastructure_iam_user" {
  description = "Available if an infrastructure IAM user had to be created"

  value = { for this_user, these_values in module.infrastructure_permissions :
    this_user => these_values.iam_user
  }
}

output "application_iam_user" {
  description = "Available if an application IAM user had to be created"

  value = { for this_user, these_values in module.permissions :
    this_user => these_values.iam_user
  }
}

output "workspaces" {
  value = tfe_workspace.this
}
