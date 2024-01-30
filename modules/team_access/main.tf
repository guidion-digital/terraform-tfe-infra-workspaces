data "tfe_team" "these" {
  for_each = var.teams

  name         = each.key
  organization = var.organization
}

resource "tfe_team_access" "this" {
  for_each = var.teams

  team_id      = lookup(data.tfe_team.these, each.key).id
  workspace_id = var.workspace_id

  permissions {
    runs              = each.value.runs
    variables         = each.value.variables
    state_versions    = each.value.state_versions
    sentinel_mocks    = each.value.sentinel_mocks
    workspace_locking = each.value.workspace_locking
    run_tasks         = each.value.run_tasks
  }
}
