# aws-cfn-github-oidc-and-runner

AWS CloudFormation templates for GitHub OIDC provider and Actions runner on AWS

This repository provides CloudFormation templates equivalent to the Terraform module
[terraform-aws-github-oidc-and-runner](https://github.com/dceoy/terraform-aws-github-oidc-and-runner).

## Stacks

| Template | Description |
| --- | --- |
| [oidc.cfn.yaml](oidc.cfn.yaml) | GitHub OIDC identity provider and IAM role for GitHub Actions |
| [kms.cfn.yaml](kms.cfn.yaml) | KMS key for CloudWatch Logs encryption |
| [codebuild.cfn.yaml](codebuild.cfn.yaml) | CodeBuild project as GitHub Actions self-hosted runner |

## Usage

### 1. Deploy the OIDC stack

```sh
aws cloudformation deploy \
  --stack-name gha-dev-oidc \
  --template-file oidc.cfn.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    IamRoleName=iac \
    GitHubRepositoriesRequiringOidc='repo:dceoy/*:*' \
    IamPolicyArns='arn:aws:iam::aws:policy/AdministratorAccess'
```

### 2. Deploy the KMS stack (optional)

```sh
aws cloudformation deploy \
  --stack-name gha-dev-kms \
  --template-file kms.cfn.yaml \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev
```

### 3. Deploy the CodeBuild stack

```sh
aws cloudformation deploy \
  --stack-name gha-dev-codebuild \
  --template-file codebuild.cfn.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    GitHubRepository=dceoy/terraform-aws-github-oidc-and-runner \
    KmsKeyArn=<KMS_KEY_ARN>
```

### Multiple IAM roles

Deploy additional OIDC stacks with `EnableGitHubOidc=false` to create more IAM roles
sharing the same OIDC provider:

```sh
aws cloudformation deploy \
  --stack-name gha-dev-oidc-llm \
  --template-file oidc.cfn.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    EnableGitHubOidc=false \
    IamRoleName=llm \
    GitHubRepositoriesRequiringOidc='repo:dceoy/*:*' \
    IamPolicyArns='arn:aws:iam::aws:policy/AmazonBedrockFullAccess'
```

### Multiple CodeBuild runners

Deploy additional CodeBuild stacks for each repository:

```sh
aws cloudformation deploy \
  --stack-name gha-dev-codebuild-another-repo \
  --template-file codebuild.cfn.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SystemName=gha \
    EnvType=dev \
    GitHubRepository=dceoy/another-repo
```
