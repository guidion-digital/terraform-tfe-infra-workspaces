data "aws_secretsmanager_secret" "aws_access_key" {
  name = "TerraformSecrets"
}

data "aws_secretsmanager_secret_version" "aws_access_key" {
  secret_id = data.aws_secretsmanager_secret.aws_access_key.id
}

locals {
  aws_access_key_id     = jsondecode(data.aws_secretsmanager_secret_version.aws_access_key.secret_string)["access_key"]
  aws_secret_access_key = jsondecode(data.aws_secretsmanager_secret_version.aws_access_key.secret_string)["secret_key"]
}

resource "tfe_variable" "aws_region" {
  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_REGION"
  value        = var.aws_region
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "aws_access_key_id" {
  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_ACCESS_KEY_ID"
  value        = local.aws_access_key_id
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "aws_secret_access_key" {
  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = local.aws_secret_access_key
  category     = "env"
  workspace_id = var.workspace_id
  sensitive    = true
}
