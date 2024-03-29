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

Please see the [Terrappy Permissions](https://github.com/guidion-digital/terrappy/blob/master/permissions.md) page for how permissions for both the workspaces and applications that they deploy, works.

## Good-to-Knows and Gotchyas

It is _not_ possible to pass a non-pre-existing policy to `application_policy_arns`. If custom policies are needed for the default application role, you can either create a role with them and pass it to `application_role_arn_names`, or pass the policy string to `application_policy`.

The role that applications are permitted to assume include policies granting access to additional AWS resources such as DynamoDB, if listed in `var.applications{}.supporting_services`. Permissions restrict resources by the application's name as a namespace. E.g. an application called `app-x` will be permitted read/write to tables named `arn:aws:dynamodb:*:*:table/app-x-*`

When supplying the `var.applications{}.github` object, ensure that the token being used in your Github provider definition has access to the repository referenced.
