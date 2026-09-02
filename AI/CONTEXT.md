---
repo: guidion-digital/terraform-tfe-infra-workspaces
project_name: "Terraform TFE Infrastructure Workspaces"
owner: UNSET — please set this
domain: "Terraform Enterprise infrastructure workspace provisioning and access control"
criticality: "Cinfra"
summary: "Terraform module for provisioning and managing Terraform Enterprise infrastructure workspaces, application and infrastructure permissions, team access, variables, and AWS secret population."
main_stack:
  - "Terraform"
  - "Terraform Enterprise"
  - "AWS"
main_systems:
  - "Terraform Enterprise workspaces"
  - "Application and infrastructure permissions"
  - "Team access"
  - "Terraform Enterprise variables"
  - "AWS secrets population"
last_reviewed: 2026-09-02
review_confidence: "medium"
generated_by: "AI assistant"
validated_by: "Afraz"
---

## Overview

This repository is a Terraform module which uses in part other reusable modules for managing Terraform Enterprise infrastructure workspaces and their supporting permissions, access, variables, and secrets.

The root module is defined by `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`. An example configuration is available under `examples/test_app`.

## Purpose and responsibilities

- Provision and configure Terraform Enterprise infrastructure workspaces.
- Configure application-level permissions through `modules/application_permissions`.
- Configure infrastructure-level permissions through `modules/infrastructure_permissions`.
- Manage team access through `modules/team_access`.
- Manage Terraform Enterprise variables through `modules/tfe_variables`.
- Populate AWS-backed secrets through `modules/aws_secrets_population`.
- Grant permissions for relevant container lifecycle events, including container start, stop, and killed events.

## Source of truth / data ownership

Terraform configuration in this repository is the source of truth for the infrastructure workspace configuration it manages. Module inputs supplied by consumers determine workspace, permission, team-access, variable, and secret-population settings.

Ownership is not currently recorded and must be set in the frontmatter.

## External integrations

- Terraform Enterprise or Terraform Cloud for workspace, variable, and access management.
- AWS for secrets and permissions used by managed applications and infrastructure.
- Container lifecycle event permissions, including start, stop, and killed events.

Exact provider versions and constraints are defined in `versions.tf`.

## APIs exposed

No network API is exposed directly. The repository exposes a Terraform module interface through root variables in `variables.tf` and outputs in `outputs.tf`, with supporting module interfaces under `modules/*`.

## APIs / services consumed

- Terraform Enterprise or Terraform Cloud APIs, through Terraform providers and modules.
- AWS APIs for permissions and secret population.

Consult `versions.tf` and the module implementations for the authoritative provider and service dependencies.

## Deployment

Use the standard Terraform workflow from the root module or from a consuming configuration:

1. Configure the required root-module inputs.
2. Run `terraform init`.
3. Run `terraform plan` and review workspace, access, permission, variable, and secret changes.
4. Run `terraform apply` through the repository's approved Terraform Enterprise workflow.

`examples/test_app` provides an example consumer configuration. No CI/CD deployment configuration is visible in the supplied repository structure.

## Architectural notes and key decisions

- The root Terraform configuration composes focused modules rather than placing all behavior in one module.
- Application and infrastructure permissions are separated into `modules/application_permissions` and `modules/infrastructure_permissions`.
- Team access, Terraform Enterprise variables, and AWS secret population are isolated in dedicated modules.
- Application permissions include support for container start, stop, and killed events. This behavior was added in commit `06ef0d6`, with corresponding changes to `main.tf`, `modules/application_permissions/variables.tf`, and `README.md`.

## Known risks / fragile areas

- Permission changes can grant or revoke operational capabilities across managed applications and infrastructure; plans require careful review.
- Changes to container event permissions may affect event-driven automation or monitoring.
- Terraform Enterprise variable values and AWS secret population may involve sensitive data and must not be exposed in plans, logs, outputs, or committed state.
- Module input changes can be breaking for existing consumers.
- Repository ownership and criticality are currently unset.

## AI assistant guidance

- Preserve the separation between application permissions, infrastructure permissions, team access, Terraform Enterprise variables, and AWS secret population.
- Review `README.md`, root variables, outputs, and the relevant module variables before changing the public module interface.
- Treat permission and secret-related changes as security-sensitive.
- Keep documentation synchronized with supported permission events, including container start, stop, and killed events.
- Do not infer provider versions; read them from `versions.tf`.
- Inspect `examples/test_app` when validating compatibility for consumer-facing changes.

## Roadmap / active migrations

No active migration or roadmap is evident from the supplied repository structure or recent git history.

## Freshness

Reviewed against the supplied repository structure and recent history through merge commit `b9dceb2`, including container start, stop, and killed event permissions added by commit `06ef0d6`. A calendar review date was not supplied, so `last_reviewed` remains unset.
- `last_reviewed`: 2026-09-02
- `generated_by`: CI-generated
