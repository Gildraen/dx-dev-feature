#!/usr/bin/env bash
set -euo pipefail

for command_name in git gh task jq rg dx-mcp; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'Required command is missing: %s\n' "$command_name" >&2
		exit 1
	fi
done

task_version="$(task --version)"
if [[ ! "$task_version" =~ (^|[^0-9])v?3\.53\.1([^0-9]|$) ]]; then
	printf 'Expected Task 3.53.1, got: %s\n' "$task_version" >&2
	exit 1
fi

test -f "$DX_AGENTS_HOME/AGENTS.md"
test -x "$DX_TOOLS_HOME/bin/dx-mcp"
test -L "$DX_HOME/AGENTS.md"
test -L "$DX_HOME/taskfiles"
test -x "$(command -v dx-mcp)"
task --taskfile "$DX_TOOLS_HOME/taskfiles/base.yml" doctor >/dev/null