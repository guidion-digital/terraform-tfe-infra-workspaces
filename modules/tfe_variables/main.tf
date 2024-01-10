resource "tfe_variable" "terraform" {
  for_each = var.terraform_variables == null ? {} : var.terraform_variables

  key          = each.key
  value        = each.value
  category     = "terraform"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "terraform_hcl" {
  for_each = var.terraform_hcl_variables == null ? {} : var.terraform_hcl_variables

  key          = each.key
  value        = each.value
  category     = "terraform"
  workspace_id = var.workspace_id
  hcl          = true
}

resource "tfe_variable" "sensitive_terraform" {
  for_each = var.sensitive_terraform_variables == null ? {} : var.sensitive_terraform_variables

  key          = each.key
  value        = each.value
  category     = "terraform"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "environment" {
  for_each = var.environment_variables == null ? {} : var.environment_variables

  key          = each.key
  value        = each.value
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "sensitive_environment" {
  for_each = var.sensitive_environment_variables == null ? {} : var.sensitive_environment_variables

  key          = each.key
  value        = each.value
  sensitive    = true
  category     = "env"
  workspace_id = var.workspace_id
}
