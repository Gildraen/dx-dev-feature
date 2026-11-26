# DX Dev Feature

Dev Container Features for shared development prerequisites.

## `dev-prerequisites`

Installs Git, GitHub CLI, and Go Task 3.53.1. The feature adds no project-specific
configuration, authentication state, agents, or MCP servers.

```json
{
	"features": {
		"ghcr.io/gildraen/dx-dev-feature/dev-prerequisites:1": {}
	}
}
```

The feature is published after changes reach `main`. GHCR creates the package
as private by default, so an owner must make it public before anonymous pulls
work. Making a package public cannot be undone.

## Validation

Run the contract check with `node scripts/validate-contract.mjs`. Run the full
feature test with `bash scripts/feature-test.sh`; this requires Docker.
