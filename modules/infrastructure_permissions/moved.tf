# State address migrations for backward compatibility when resources changed
# from singleton to counted instances.

moved {
  from = aws_iam_policy.role_boundary
  to   = aws_iam_policy.role_boundary[0]
}

moved {
  from = aws_iam_role.workspace
  to   = aws_iam_role.workspace[0]
}

moved {
  from = aws_iam_role_policy_attachment.this
  to   = aws_iam_role_policy_attachment.this[0]
}

moved {
  from = aws_iam_user.this
  to   = aws_iam_user.this[0]
}

moved {
  from = aws_iam_access_key.this
  to   = aws_iam_access_key.this[0]
}

moved {
  from = tfe_variable.aws_access_key_id
  to   = tfe_variable.aws_access_key_id[0]
}

moved {
  from = tfe_variable.aws_secret_access_key
  to   = tfe_variable.aws_secret_access_key[0]
}

moved {
  from = tfe_variable.tfc_aws_provider_auth
  to   = tfe_variable.tfc_aws_provider_auth[0]
}

moved {
  from = tfe_variable.tfc_aws_run_role_arn
  to   = tfe_variable.tfc_aws_run_role_arn[0]
}

moved {
  from = aws_secretsmanager_secret.workspace_access_key
  to   = aws_secretsmanager_secret.workspace_access_key[0]
}

moved {
  from = aws_secretsmanager_secret_version.workspace_access_key
  to   = aws_secretsmanager_secret_version.workspace_access_key[0]
}

moved {
  from = aws_iam_user_policy_attachment.this
  to   = aws_iam_user_policy_attachment.this[0]
}
