#!/usr/bin/env bash
set -euo pipefail

npx --yes @devcontainers/cli@0.88.0 features test \
	--features dx \
	--project-folder . \
	--base-image mcr.microsoft.com/devcontainers/base:ubuntu-24.04 \
	--remote-user vscode \
	--skip-scenarios \
	--skip-duplicated