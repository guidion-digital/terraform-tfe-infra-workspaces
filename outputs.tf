output "application_iam_role_arns" {
  value = { for k, v in module.permissions : k => v.application_iam_role_arn }
}

output "workspace_ids" {
  value = { for this_workspace, these_values in tfe_workspace.this : this_workspace => these_values.id }
}

output "infrastructure_iam_role" {
  description = "Available if an infrastructure IAM role had to be created"

  value = { for this_role, these_values in module.infrastructure_permissions :
    this_role => these_values.iam_role
  }
}

output "application_iam_role" {
  description = "Available if an application IAM role had to be created"

  value = { for this_role, these_values in module.permissions :
    this_role => these_values.iam_role
  }
}

output "infrastructure_iam_user" {
  description = "Deprecated: use infrastructure_iam_role instead"

  value = { for this_role, these_values in module.infrastructure_permissions :
    this_role => these_values.iam_role
  }
}

output "application_iam_user" {
  description = "Deprecated: use application_iam_role instead"

  value = { for this_role, these_values in module.permissions :
    this_role => these_values.iam_role
  }
}

output "workspaces" {
  value = tfe_workspace.this
}
