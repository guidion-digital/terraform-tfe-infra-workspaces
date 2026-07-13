data "aws_caller_identity" "current" {}

locals {
  tfc_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/app.terraform.io"
}

# Bounds what var.workspace_policy (opaque/caller-supplied) is allowed to grant.
# Even if that policy grants IAM write permissions, the role can never modify
# its own trust policy, permissions boundary, or attached policies, and can't
# create/delete other /tfe/ roles. This keeps the OIDC trust conditions above
# from being rewritten by a run using this role.
data "aws_iam_policy_document" "role_boundary" {
  count = var.use_oidc ? 1 : 0

  statement {
    sid       = "AllowAll"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyIamSelfModification"
    effect = "Deny"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:DeleteRolePermissionsBoundary",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/tfe/*"]
  }
}

resource "aws_iam_policy" "role_boundary" {
  count = var.use_oidc ? 1 : 0

  name   = "${var.name}-role-boundary"
  path   = "/tfe/"
  policy = one(data.aws_iam_policy_document.role_boundary[*].json)
}

resource "aws_iam_role" "workspace" {
  count = var.use_oidc ? 1 : 0

  name                 = var.name
  path                 = "/tfe/"
  permissions_boundary = one(aws_iam_policy.role_boundary[*].arn)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRoleWithWebIdentity"
        Principal = { Federated = local.tfc_oidc_provider_arn }
        Condition = {
          StringEquals = {
            "app.terraform.io:aud" = "aws.workload.identity"
          }
          StringLike = {
            "app.terraform.io:sub" = "organization:${var.organization}:project:*:workspace:${var.name}:run_phase:*"
          }
        }
      }
    ]
  })

  tags = {
    source = "tfe"
  }
}

resource "aws_iam_user" "this" {
  count = var.use_oidc ? 0 : 1

  name = var.name
  path = "/tfe/"

  tags = {
    source = "tfe"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.use_oidc && var.workspace_policy != null ? 1 : 0

  role       = one(aws_iam_role.workspace[*].name)
  policy_arn = var.workspace_policy
}

resource "aws_iam_user_policy_attachment" "this" {
  count = !var.use_oidc && var.workspace_policy != null ? 1 : 0

  user       = one(aws_iam_user.this[*].name)
  policy_arn = var.workspace_policy
}

resource "aws_iam_access_key" "this" {
  count = var.use_oidc ? 0 : 1

  user = one(aws_iam_user.this[*].name)
}

resource "tfe_variable" "aws_region" {
  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_REGION"
  value        = var.aws_region
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "aws_access_key_id" {
  count = var.use_oidc ? 0 : 1

  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_ACCESS_KEY_ID"
  value        = one(aws_iam_access_key.this[*].id)
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "aws_secret_access_key" {
  count = var.use_oidc ? 0 : 1

  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = one(aws_iam_access_key.this[*].secret)
  category     = "env"
  workspace_id = var.workspace_id
  sensitive    = true
}

locals {
  access_key = var.use_oidc ? null : {
    aws_access_key_id     = one(aws_iam_access_key.this[*].id)
    aws_secret_access_key = one(aws_iam_access_key.this[*].secret)
  }
}

resource "aws_secretsmanager_secret" "workspace_access_key" {
  count = var.use_oidc ? 0 : 1

  name = "terraform-cloud/workspace/${one(aws_iam_user.this[*].name)}/access-key"
}

resource "aws_secretsmanager_secret_version" "workspace_access_key" {
  count = var.use_oidc ? 0 : 1

  secret_id     = one(aws_secretsmanager_secret.workspace_access_key[*].id)
  secret_string = jsonencode(local.access_key)
}

resource "tfe_variable" "tfc_aws_provider_auth" {
  count = var.use_oidc ? 1 : 0

  description  = "Enable HCP Terraform dynamic AWS credentials"
  key          = "TFC_AWS_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "tfc_aws_run_role_arn" {
  count = var.use_oidc ? 1 : 0

  description  = "IAM role ARN to assume via OIDC"
  key          = "TFC_AWS_RUN_ROLE_ARN"
  value        = one(aws_iam_role.workspace[*].arn)
  category     = "env"
  workspace_id = var.workspace_id
}
