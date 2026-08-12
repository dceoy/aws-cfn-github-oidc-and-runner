#!/usr/bin/env bash

set -euox pipefail

cd "$(git rev-parse --show-toplevel)"

COOLDOWN_DAYS=7
export UV_EXCLUDE_NEWER="${COOLDOWN_DAYS} days"
export NPM_CONFIG_MIN_RELEASE_AGE="${COOLDOWN_DAYS}"
export PNPM_CONFIG_MINIMUM_RELEASE_AGE=$((COOLDOWN_DAYS * 24 * 60))

npx -y prettier --write './**/*.md'
uvx zizmor --fix=safe .github/workflows
git ls-files -z -- '*.yml' '*.yaml' | xargs -0 -t uvx yamllint -d '{"extends": "relaxed", "rules": {"line-length": "disable"}}'
git ls-files -z -- '*.cfn.yml' '*.cfn.yaml' | xargs -0 -t uvx cfn-lint
git ls-files -z -- '.github/workflows/*.yml' '.github/workflows/*.yaml' | xargs -0 -t actionlint
uvx checkov --framework=all --output=github_failed_only --directory=.
trivy filesystem --scanners vuln,secret,misconfig --skip-dirs .git .
