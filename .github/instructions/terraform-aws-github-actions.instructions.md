---
description: "Use when creating or modifying Terraform AWS infrastructure, stack definitions, or GitHub Actions CI/CD workflows. Enforces secure defaults, reusable placeholders, and environment-safe conventions."
name: "Terraform AWS and GitHub Actions Guardrails"
applyTo: "**/*.{tf,tfvars,hcl}|.github/workflows/*.{yml,yaml}"
---
# Terraform (AWS) and GitHub Actions Instructions

- Use Terraform as the source of truth for AWS infrastructure changes.
- Keep modules and stacks reusable across environments (dev, stage, prod).
- Never hardcode uniquely identifying values.
- Always use placeholders for sensitive or environment-unique values.

## Required Placeholders

- Project or stack identifier: `<PROJECT_OR_STACK_NAME>`
- AWS account ID: `<AWS_ACCOUNT_ID>`
- AWS region: `<AWS_REGION>`
- Deployment environment: `<ENVIRONMENT>`
- IAM role ARN for GitHub OIDC: `<GITHUB_OIDC_ROLE_ARN>`
- Terraform backend bucket: `<TF_STATE_BUCKET_NAME>`
- Terraform backend DynamoDB lock table: `<TF_LOCK_TABLE_NAME>`

## Terraform Rules

- Do not commit real account IDs, ARNs, domain names, repository secrets, or production resource names.
- Prefer variables with validations over inline literals.
- Use remote state and state locking for team workflows.
- Pin provider and module versions explicitly.
- Tag resources consistently with environment, owner, and cost-center metadata using non-identifying placeholders.
- Keep least privilege IAM policies and avoid wildcard `*` actions/resources unless justified.

## GitHub Actions Rules

- Use OIDC-based AWS authentication (`aws-actions/configure-aws-credentials`) instead of long-lived static keys.
- Use least privilege role assumption and environment protections.
- Pin third-party actions to immutable versions (prefer commit SHA; at minimum major-version pin).
- Never print secrets or credentials to logs.
- Use concurrency controls for deploy workflows to avoid overlap.
- Separate plan/validate from apply/deploy steps.

## Output and Example Conventions

- Example values must stay generic and non-identifying.
- Use this style in generated snippets:

```hcl
variable "project_or_stack_name" {
  description = "Logical stack or project identifier"
  type        = string
  default     = "<PROJECT_OR_STACK_NAME>"
}

variable "aws_account_id" {
  description = "Target AWS account"
  type        = string
  default     = "<AWS_ACCOUNT_ID>"
}
```

```yaml
env:
  PROJECT_OR_STACK_NAME: <PROJECT_OR_STACK_NAME>
  AWS_ACCOUNT_ID: <AWS_ACCOUNT_ID>
  AWS_REGION: <AWS_REGION>
```

## Review Checklist

- Confirm no unique or sensitive identifiers are present.
- Confirm all environment-specific values are parameterized.
- Confirm Terraform and workflow files are version-pinned and security-hardened.
- Confirm naming remains placeholder-based until user-provided values are supplied.
