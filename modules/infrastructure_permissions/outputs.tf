output "iam_user" {
  description = "Name of the IAM user that gets created"
  value       = aws_iam_user.this.name
}
