Part of the [Terrappy framework](https://github.com/guidion-digital/terrappy).

---

Use to configure your TFE workspaces in a uniform way, and make their creation easier. It's been created in such a way as to be usable for both [infrastructure level workspaces, and application level workspaces](https://github.com/guidion-digital/terrappy) (see the [examples](./examples) folder for usage).

# Rationale

The purpose of this module is to ensure:

1. Uniformity in your TFC workspaces, meaning things like tagging and naming are consistent, but also permissions are set correctly
1. Automation in workspace creation (and deletion!)
1. Everything is in place for a new application deployment, encouraging procedure enforcement

That last one is encouraged by the automation of AWS credentials and permissions. This means that if an application does not declare it's intentions for AWS — i.e. if we are not told about it — then it simply won't work, since the credentials provided to the workspace will not have permissions to create those undeclared resources.

# Usage

See the [examples](./examples/test_app/README.md) for how to create application or infrastructure workspaces. The presence of the `applications` variable is enough to trigger the creation of these different types of workspaces.

So called "infrastructure" workspaces are those that later run this module themselves, in order to create the "application" workspaces they're responsible for.

# Permissions

For each entry in `var.applications`:

- A TFC workspace will be created
- An IAM user will be created, along with credentials which will be populated into workspace's `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` variables. The IAM user will:
  - Have only the permissions necessary to create the application module's resources, by either:
    - Specifying `var.applications{}.workspace_policy` with a fully formed JSON policy document
    - Specifying one of `cdn`, `api`, or `container` for `var.applications{}.app_type` (you will also need to set `var.applications{}.domain_account_role` in this case)
  - Be able to pass the application IAM roles to the application (see next point)
- IAM roles for use with the resources deployed (the application) will be _created_ and/or _accepted_ as arguments:
  - **Created** if either `application_policy_arns` or `application_policies` is given (see [example "api-app-x"](./examples/application/main.tf)). In this case, a variable called `var.role_arn` will be created in the workspace, containing the ARN of a role with the provided policies. **`service_types` must also be set**
  - **Accepted** if `application_role_arn_names` is given of existing roles (see [example "api-app-y"](./examples/application/main.tf))
  - All three can be provided, in which case the workspace IAM user will be permitted to pass a concatenation of the passed roles, and the role the module creates
- A policy with additional permissions for the application will be created based on the values in `var.applications{}.supporting_services`, which gives necessary permissions to supporting resources such as DynamoDB tables, restricted by namespacing based on the application name

Note that the only roles the application resources can be passed are those this module knows about via `application_role_arn_names`, `application_policy_arns`, or `application_policies`.

## Good-to-Knows and Gotchyas

It is _not_ possible to pass a non-pre-existing policy to `application_policy_arns`. If custom policies are needed for the default application role, you can either create a role with them and pass it to `application_role_arn_names`, or pass the policy string to `application_policy`.

The role that applications are permitted to assume include policies granting access to additional AWS resources such as DynamoDB, if listed in `var.applications{}.supporting_services`. Permissions restrict resources by the application's name as a namespace. E.g. an application called `app-x` will be permitted read/write to tables named `arn:aws:dynamodb:*:*:table/app-x-*`
