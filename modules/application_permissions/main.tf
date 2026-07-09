## Application Permissions

locals {
  services                = [for this_service in var.service_types : "${this_service}.amazonaws.com"]
  create_application_role = length(local.services) != 0 && (length(var.application_policy_arns) != 0 || var.application_policy != null)
}

# We create an IAM role here which will be in the allowed list of roles that
# this workspace IAM role will be able to pass on to its services. This is
# done with aws_iam_policy.pass_role below
resource "aws_iam_role" "application" {
  count = local.create_application_role == true ? 1 : 0

  name = var.name
  path = "/application/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = { Service = local.services }
      },
    ]
  })

  tags = {
    source = "tfe"
  }
}

resource "aws_iam_instance_profile" "this" {
  count = var.ec2_app != null ? 1 : 0

  name = var.name
  role = one(aws_iam_role.application[*].name)
}

resource "aws_iam_role_policy_attachment" "application" {
  for_each = local.create_application_role == true && length(var.application_policy_arns) != 0 ? toset(var.application_policy_arns) : []

  role       = one(aws_iam_role.application[*].name)
  policy_arn = each.value
}

resource "aws_iam_policy" "this" {
  count = length(var.application_policy) != 0 ? 1 : 0

  name   = "aux-${var.name}"
  path   = "/application/"
  policy = var.application_policy
}

resource "aws_iam_role_policy_attachment" "aux" {
  count = local.create_application_role == true && length(var.application_policy) != 0 ? 1 : 0

  role       = one(aws_iam_role.application[*].name)
  policy_arn = aws_iam_policy.this[0].arn
}

# We create a policy based on a set of services that the application in this
# workspace is going to use (currently just SQS and DynamoDB are supported).
# Then we attach it to the default application role created above
# (aws_iam_role.application)
#
# This is documented properly here:
#
# https://github.com/guidion-digital/terrappy/blob/master/permissions.md
module "services_policy" {
  source  = "guidion-digital/helper-application-policy/aws"
  version = "1.0.0"

  application_name = var.application_name

  sqs_queues = contains(var.supporting_services, "sqs") ? ["arn:aws:sqs:*:*:${var.application_name}-*"] : null
  dynamodb_tables = contains(var.supporting_services, "dynamodb") ? [
    "arn:aws:dynamodb:*:*:table/${var.application_name}-*",
    "arn:aws:dynamodb:*:*:table/${var.application_name}-*/stream/*",
    "arn:aws:dynamodb:*:*:table/${var.application_name}-*/*/*",
    "arn:aws:dynamodb:*:*:table/${var.application_name}/stream/*"
  ] : null
}

resource "aws_iam_role_policy_attachment" "application_policy" {
  count = local.create_application_role == true ? 1 : 0

  role       = one(aws_iam_role.application[*].name)
  policy_arn = module.services_policy.policy_arn
}

## TFE Permissions

data "aws_caller_identity" "current" {}

locals {
  tfc_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/app.terraform.io"
}

# Bounds what gets attached to this role below (helper-workspace-policy output,
# pass_role, etc). Even if one of those grants IAM write permissions, the role
# can never modify its own trust policy, permissions boundary, or attached
# policies, and can't create/delete other /tfe/ roles. This keeps the OIDC
# trust conditions above from being rewritten by a run using this role.
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

data "aws_iam_role" "supplied_application_roles" {
  count = length(var.application_role_arn_names)

  name = var.application_role_arn_names[count.index]
}

# We give the IAM role that TFC will assume permission to:
#
#   * Create resources necessary for the application
#   * Pass the application role created above / passed to us, to the services using them
#
resource "aws_iam_policy" "pass_role" {
  name = "${var.name}-passrole"
  path = "/tfe/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:PassRole", "iam:GetRole"]
        Resource = concat(
          data.aws_iam_role.supplied_application_roles[*].arn,
          aws_iam_role.application[*].arn,
          var.application_role_arns[*]
        )
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.workspace_policy != null ? 1 : 0

  role       = aws_iam_role.workspace.name
  policy_arn = var.workspace_policy
}

module "workspace_user_policy" {
  source  = "guidion-digital/helper-workspace-policy/aws"
  version = "~> 2.0"

  application_name     = var.application_name
  application_role_arn = one(aws_iam_role.application[*].arn)
  project              = var.project
  domain_account_role  = var.domain_account_role

  cdn_app       = var.cdn_app
  api_app       = var.api_app
  lambda_app    = var.lambda_app
  container_app = var.container_app
  ec2_app       = var.ec2_app
}

resource "aws_iam_role_policy_attachment" "cdn_policies" {
  count = length(module.workspace_user_policy.cdn_type_policy_arns)

  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.cdn_type_policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "api_policies" {
  count = length(module.workspace_user_policy.api_type_policy_arns)

  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.api_type_policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "lambda_policies" {
  count = length(module.workspace_user_policy.lambda_type_policy_arns)

  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.lambda_type_policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "container_policies" {
  count = length(module.workspace_user_policy.container_type_policy_arns)

  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.container_type_policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "ec2_policies" {
  count = length(module.workspace_user_policy.ec2_type_policy_arns)

  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.ec2_type_policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "secrets_policy" {
  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.secrets_policy_arn
}

resource "aws_iam_role_policy_attachment" "ssm_parameters_policy" {
  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.ssm_parameters_policy_arn
}

resource "aws_iam_role_policy_attachment" "s3_bucket_policy" {
  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.s3_bucket_policy_arn
}

resource "aws_iam_role_policy_attachment" "elasticache_policy" {
  count = contains(var.supporting_services, "elasticache") ? 1 : 0

  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.elasticache_policy_arn
}

resource "aws_iam_role_policy_attachment" "common_policy" {
  role       = aws_iam_role.workspace.name
  policy_arn = module.workspace_user_policy.common_policy_arn
}

resource "aws_iam_role_policy_attachment" "pass_role" {
  role       = aws_iam_role.workspace.name
  policy_arn = aws_iam_policy.pass_role.arn
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
