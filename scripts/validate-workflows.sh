#!/usr/bin/env bash
set -euo pipefail

for workflow in .github/workflows/*.yaml; do
	npx --yes js-yaml "$workflow" >/dev/null
done

printf 'Workflow YAML parses\n'