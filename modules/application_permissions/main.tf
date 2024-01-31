## Application Permissions

locals {
  services                = [for this_service in var.service_types : "${this_service}.amazonaws.com"]
  create_application_role = length(local.services) != 0 && (length(var.application_policy_arns) != 0 || var.application_policy != null)
}

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

module "services_policy" {
  source  = "app.terraform.io/guidion/helper-application-policy/aws"
  version = "0.0.4"

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

resource "aws_iam_user" "this" {
  name = var.name
  path = "/tfe/"

  tags = {
    source = "tfe"
  }
}

data "aws_iam_role" "supplied_application_roles" {
  count = length(var.application_role_arn_names)

  name = var.application_role_arn_names[count.index]
}

# We give the IAM user that TFC will use permission to:
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
        Effect   = "Allow"
        Action   = ["iam:PassRole", "iam:GetRole"]
        Resource = concat(data.aws_iam_role.supplied_application_roles[*].arn, aws_iam_role.application[*].arn)
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "this" {
  count = var.workspace_policy != null ? 1 : 0

  user       = aws_iam_user.this.name
  policy_arn = var.workspace_policy
}

module "workspace_user_policy" {
  source  = "app.terraform.io/guidion/helper-workspace-policy/aws"
  version = "~> 2.0"

  application_name     = var.application_name
  application_role_arn = one(aws_iam_role.application[*].arn)
  project              = var.project
  domain_account_role  = var.domain_account_role

  cdn_app       = var.cdn_app
  api_app       = var.api_app
  container_app = var.container_app
}

resource "aws_iam_user_policy_attachment" "cdn_policies" {
  count = length(module.workspace_user_policy.cdn_type_policy_arns)

  user       = aws_iam_user.this.name
  policy_arn = module.workspace_user_policy.cdn_type_policy_arns[count.index]
}

resource "aws_iam_user_policy_attachment" "api_policies" {
  count = length(module.workspace_user_policy.api_type_policy_arns)

  user       = aws_iam_user.this.name
  policy_arn = module.workspace_user_policy.api_type_policy_arns[count.index]
}

resource "aws_iam_user_policy_attachment" "container_policies" {
  count = length(module.workspace_user_policy.container_type_policy_arns)

  user       = aws_iam_user.this.name
  policy_arn = module.workspace_user_policy.container_type_policy_arns[count.index]
}

resource "aws_iam_user_policy_attachment" "secrets_policy" {
  user       = aws_iam_user.this.name
  policy_arn = module.workspace_user_policy.secrets_policy_arn
}

resource "aws_iam_user_policy_attachment" "common_policy" {
  user       = aws_iam_user.this.name
  policy_arn = module.workspace_user_policy.common_policy_arn
}

resource "aws_iam_user_policy_attachment" "pass_role" {
  user       = aws_iam_user.this.name
  policy_arn = aws_iam_policy.pass_role.arn
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
