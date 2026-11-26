#!/usr/bin/env bash
set -euo pipefail

for command_name in git gh task; do
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

git --version
gh --version | head -n 1
printf '%s\n' "$task_version"