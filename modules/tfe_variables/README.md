Handles creation of Terraform Cloud variables.

Note that `var.hcl_variables` are maps, and must be given in heredoc format. e.g.

```hcl
"terraform_hcl_variables" = {
  "api_keys_share" = <<EOT
    {
      "AWS" = ["arn:aws:iam::123456789012:role/Read-Only"]
    }
  EOT
}
```
