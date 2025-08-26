resource "aws_iam_role" "tfe_infra_workspaces_test" {
  name        = "tfe-infra-workspaces-test"
  description = "Dummy role used for tfe-infra-workspaces module example"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "lambda.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}
