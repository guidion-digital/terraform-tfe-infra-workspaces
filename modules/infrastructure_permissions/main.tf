resource "aws_iam_user" "this" {
  name = var.name
  path = "/tfe/"

  tags = {
    source = "tfe"
  }
}

resource "aws_iam_user_policy_attachment" "this" {
  count = var.workspace_policy != null ? 1 : 0

  user       = aws_iam_user.this.name
  policy_arn = var.workspace_policy
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
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
  value        = aws_iam_access_key.this.id
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "aws_secret_access_key" {
  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = aws_iam_access_key.this.secret
  category     = "env"
  workspace_id = var.workspace_id
  sensitive    = true
}

locals {
  access_key = {
    aws_access_key_id     = aws_iam_access_key.this.id
    aws_secret_access_key = aws_iam_access_key.this.secret
  }
}

resource "aws_secretsmanager_secret" "workspace_access_key" {
  name = "terraform-cloud/workspace/${aws_iam_user.this.name}/access-key"
}

resource "aws_secretsmanager_secret_version" "workspace_access_key" {
  secret_id     = aws_secretsmanager_secret.workspace_access_key.id
  secret_string = jsonencode(local.access_key)
}
