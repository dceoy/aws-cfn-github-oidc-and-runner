# aws-cfn-github-oidc-and-runner

AWS CloudFormation templates for GitHub OIDC provider, CodeConnections
connection, and Actions runner on AWS

This repository provides CloudFormation templates equivalent to the Terraform module
[terraform-aws-github-oidc-and-runner](https://github.com/dceoy/terraform-aws-github-oidc-and-runner).

## Stacks

| Template                                 | Description                                                   |
| ---------------------------------------- | ------------------------------------------------------------- |
| [oidc.cfn.yml](oidc.cfn.yml)             | GitHub OIDC identity provider and IAM role for GitHub Actions |
| [connection.cfn.yml](connection.cfn.yml) | CodeConnections connection for GitHub App authorization       |
| [kms.cfn.yml](kms.cfn.yml)               | KMS key for CloudWatch Logs encryption                        |
| [codebuild.cfn.yml](codebuild.cfn.yml)   | CodeBuild project as GitHub Actions self-hosted runner        |

## Usage

The OIDC, CodeConnections, and CodeBuild stacks are independent.

- Use `oidc.cfn.yml` when GitHub Actions needs to assume an AWS IAM role through
  GitHub OIDC.
- Use `connection.cfn.yml` when an AWS service needs a GitHub App connection
  managed by AWS CodeConnections.
- Use `codebuild.cfn.yml` when GitHub Actions needs a CodeBuild-based
  self-hosted runner.
- Use `kms.cfn.yml` only if you want to encrypt CodeBuild CloudWatch Logs with a
  customer-managed KMS key.

### GitHub OIDC for AWS IAM roles

Deploy the OIDC stack:

```sh
aws cloudformation deploy \
  --stack-name gha-dev-oidc \
  --template-file oidc.cfn.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    IamRoleName=iac \
    GitHubRepositoriesRequiringOidc='repo:dceoy/*:*' \
    IamPolicyArns='arn:aws:iam::aws:policy/AdministratorAccess'
```

#### Multiple IAM roles

Deploy additional OIDC stacks with `EnableGitHubOidc=false` to create more IAM
roles sharing the same OIDC provider:

```sh
aws cloudformation deploy \
  --stack-name gha-dev-oidc-llm \
  --template-file oidc.cfn.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    EnableGitHubOidc=false \
    IamRoleName=llm \
    GitHubRepositoriesRequiringOidc='repo:dceoy/*:*' \
    IamPolicyArns='arn:aws:iam::aws:policy/AmazonBedrockFullAccess'
```

### CodeConnections GitHub App connection

Deploy the CodeConnections stack:

```sh
aws cloudformation deploy \
  --stack-name gha-dev-connection \
  --template-file connection.cfn.yml \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    GitHubConnectionName=github-connection
```

After the stack is created, open the connection in the AWS console and complete
the GitHub authorization flow. CloudFormation-created connections stay in
`PENDING` until that step makes them `AVAILABLE`.

Use the `GitHubConnectionArn` output anywhere AWS expects a CodeConnections
connection ARN.

### CodeBuild self-hosted runners for GitHub Actions

Before deploying the CodeBuild stack, connect CodeBuild to GitHub with a
personal access token, Secrets Manager secret, OAuth app, or GitHub App
connection. For public GitHub repositories, this template creates the repository
webhook for `WORKFLOW_JOB_QUEUED` events by default. Set
`EnableGitHubWebhook=false` if you already manage the webhook yourself.
CloudFormation cannot create the webhook for GitHub Enterprise projects, so
configure it manually when `GitHubEnterpriseSlug` is set.

#### Optional: deploy the KMS stack for log encryption

```sh
aws cloudformation deploy \
  --stack-name gha-dev-kms \
  --template-file kms.cfn.yml \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev
```

#### Deploy the CodeBuild stack

```sh
aws cloudformation deploy \
  --stack-name gha-dev-codebuild \
  --template-file codebuild.cfn.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    GitHubRepository=dceoy/terraform-aws-github-oidc-and-runner \
    KmsKeyArn=<KMS_KEY_ARN>
```

#### Update the GitHub Actions workflow

After the stack is deployed, use the `CodeBuildProjectName` output in the
workflow `runs-on` label:

```yaml
name: CI

on:
  push:

jobs:
  build:
    runs-on:
      - codebuild-<CODEBUILD_PROJECT_NAME>-${{ github.run_id }}-${{ github.run_attempt }}
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello World"
```

CodeBuild also supports optional label overrides such as `image:`,
`instance-size:`, `fleet:`, and `buildspec-override:true`.

#### Multiple CodeBuild runners

Deploy additional CodeBuild stacks for each repository:

```sh
aws cloudformation deploy \
  --stack-name gha-dev-codebuild-another-repo \
  --template-file codebuild.cfn.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    GitHubRepository=dceoy/another-repo
```
