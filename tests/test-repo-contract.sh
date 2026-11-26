#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

node scripts/validate-contract.mjs
for path in README.md renovate.json Taskfile.yml release-please-config.json .release-please-manifest.json version.txt; do
	test -f "$path"
done
for workflow in validate release release-please; do
	test -f ".github/workflows/$workflow.yaml"
done
test ! -f src/dev-prerequisites/devcontainer-feature.json
test -x src/dx/install.sh
test -x src/dx/dx-mcp
test -x test/dx/test.sh
printf 'DX repository contracts pass\n'