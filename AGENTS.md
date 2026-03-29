# Repository Guidelines

## Overview

The main deliverables are [`oidc.cfn.yml`](oidc.cfn.yml), [`kms.cfn.yml`](kms.cfn.yml), and [`codebuild.cfn.yml`](codebuild.cfn.yml). The OIDC template creates the GitHub OIDC identity provider and IAM role for GitHub Actions, the KMS template creates a KMS key for CloudWatch Logs encryption, and the CodeBuild template provisions a CodeBuild project as a GitHub Actions self-hosted runner with CloudWatch Logs and an IAM service role.

## Deployment Instructions

Use the AWS CLI to deploy or update the stacks:

```bash
aws cloudformation deploy --template-file oidc.cfn.yml --stack-name gha-dev-oidc --capabilities CAPABILITY_NAMED_IAM --parameter-overrides GitHubRepositoriesRequiringOidc='repo:dceoy/*:*' IamPolicyArns='arn:aws:iam::aws:policy/AdministratorAccess'
aws cloudformation deploy --template-file kms.cfn.yml --stack-name gha-dev-kms
aws cloudformation deploy --template-file codebuild.cfn.yml --stack-name gha-dev-codebuild --capabilities CAPABILITY_NAMED_IAM --parameter-overrides GitHubRepository=dceoy/aws-cfn-github-oidc-and-runner
```

## Code Quality & Validation

**IMPORTANT**: Run the following on each change before committing.

- **format and lint**: Use the `local-qa` skill.

## Coding Style & Naming Conventions

- Write YAML with two-space indentation and keep keys aligned for readability.
- Preserve CloudFormation logical ID patterns already used in the templates.
- Parameters use PascalCase with service-prefixed names.
- Keep resource names and tags derived from `SystemName` and `EnvType`, and prefer explicit comments only when suppressing a scanner finding.

## Commit & Pull Request Guidelines

- Run QA checks using `local-qa` skill before committing or creating a PR.
- Branch names use appropriate prefixes on creation (e.g., `feature/...`, `bugfix/...`, `refactor/...`, `docs/...`, `chore/...`).
- When instructed to create a PR, create it as a draft with appropriate labels by default.

## Code Design Principles

Always prefer the simplest design that works.

- **KISS**: Choose straightforward solutions and avoid unnecessary abstraction.
- **DRY**: Remove duplication when it improves clarity and maintainability.
- **YAGNI**: Do not add features, hooks, or flexibility until they are needed.
- **SOLID/Clean Code**: Apply these as tools, only when they keep the design simpler and easier to change.

## Development Methodology

Keep delivery incremental, test-backed, and easy to review.

- Make small, safe, reversible changes.
- Prefer `Red -> Green -> Refactor`.
- Do not mix feature work and refactoring in the same commit.
- Refactor when it improves clarity or removes real duplication (Rule of Three).
- Keep tests fast, focused, and self-validating.
