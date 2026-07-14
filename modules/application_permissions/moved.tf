# State address migrations for backward compatibility when resources changed
# from singleton to counted instances.

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
  from = aws_secretsmanager_secret.workspace_access_key
  to   = aws_secretsmanager_secret.workspace_access_key[0]
}

moved {
  from = aws_secretsmanager_secret_version.workspace_access_key
  to   = aws_secretsmanager_secret_version.workspace_access_key[0]
}

moved {
  from = aws_iam_user_policy_attachment.secrets_policy
  to   = aws_iam_user_policy_attachment.secrets_policy[0]
}

moved {
  from = aws_iam_user_policy_attachment.ssm_parameters_policy
  to   = aws_iam_user_policy_attachment.ssm_parameters_policy[0]
}

moved {
  from = aws_iam_user_policy_attachment.s3_bucket_policy
  to   = aws_iam_user_policy_attachment.s3_bucket_policy[0]
}

moved {
  from = aws_iam_user_policy_attachment.common_policy
  to   = aws_iam_user_policy_attachment.common_policy[0]
}

moved {
  from = aws_iam_user_policy_attachment.pass_role
  to   = aws_iam_user_policy_attachment.pass_role[0]
}
