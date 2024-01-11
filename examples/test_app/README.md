The `main.tf` file shows an instance of this module with all possible fields (including optional ones) populated by variable values you can find in [`tests/unit.tftest.hcl`](../../tests/unit.tftest.hcl). Therefore, if you are interested in a working value for `var.applications` for example, you should explore that file to see a working value.

Below are notes on the different use cases; "applications" and "infrastructure":

# Application Workspace Usage

Including a value for `var.applications` changes how the workspace is named, tagged, and where the AWS variables come from. This mode is intended for use with a project's "applications".

## Defining Applications in `var.applications`

As stated above, to see a full definition of the `var.applications` variable, check the [`tests/unit.tftest.hcl`](../../tests/unit.tftest.hcl) file. This is a complex map describing aspects of the workspaces to be created.

It has been defined fully, so the Terraform registry should describe all the keys properly.

### Workspace Permissions

Permissions for the IAM users created for the workspaces created for each entry in `var.applications{}` are predefined based on the value passed to `var.applications{}.app_type`.

The permission sets are designed to take remove the hassle of working out what permissions the workspace needs to deploy resources. These are not to be confused with the `var.applications{}.application_policy` and `var.applications{}.application_policy_arns`, which are used by the actual applications (AWS services, such as Lambdas) themselves.

The workspace will be tagged with:

* var.project
* var.stage
* "application"

---

# Infrastructure Workspace Usage

Omitting a value for `var.applications` changes how the workspace is named, tagged, and where the AWS variables come from. This variation is intended for use on the project level. More specifically, for creating workspaces which will themselves be used to create _application_ type workspaces.

The workspace will be tagged with:

* var.project
* var.stage
* "infrastructure"

An existing AWS Secret called "TerraformSecrets" is expected to be present, with an AWS API credential set in JSON:

```json
{
  "access_key": "ACCESS_KEY",
  "secret_key": "SECRET_KEY"
}
```

These values will be picked up, and automatically populated into the workspace created, in the appropriate variables to be used automatically for authentication to AWS.
