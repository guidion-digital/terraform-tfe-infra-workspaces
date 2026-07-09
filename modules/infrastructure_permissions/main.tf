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
  name   = "${var.name}-role-boundary"
  path   = "/tfe/"
  policy = data.aws_iam_policy_document.role_boundary.json
}

resource "aws_iam_role" "workspace" {
  name                 = var.name
  path                 = "/tfe/"
  permissions_boundary = aws_iam_policy.role_boundary.arn

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

resource "aws_iam_role_policy_attachment" "this" {
  count = var.workspace_policy != null ? 1 : 0

  role       = aws_iam_role.workspace.name
  policy_arn = var.workspace_policy
}

resource "tfe_variable" "aws_region" {
  description  = "Used when accessing AWS for this workspace"
  key          = "AWS_REGION"
  value        = var.aws_region
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "tfc_aws_provider_auth" {
  description  = "Enable HCP Terraform dynamic AWS credentials"
  key          = "TFC_AWS_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  workspace_id = var.workspace_id
}

resource "tfe_variable" "tfc_aws_run_role_arn" {
  description  = "IAM role ARN to assume via OIDC"
  key          = "TFC_AWS_RUN_ROLE_ARN"
  value        = aws_iam_role.workspace.arn
  category     = "env"
  workspace_id = var.workspace_id
}
