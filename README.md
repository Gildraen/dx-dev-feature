# DX Dev Feature

This repository owns the source and release automation for the `dx` Dev
Container Feature previously maintained in `Gildraen/dx`. The `Gildraen/dx`
repository can remain the documentation catalog; `dx-agents` and `dx-tools`
remain the canonical sources for their respective resources.

## Feature

The Feature keeps its existing OCI reference so current consumers do not need
an immediate lockfile migration:

```json
{
  "features": {
    "ghcr.io/gildraen/dx/dx:1": {}
  }
}
```

It installs the existing Node, GitHub CLI, Task, and package baseline, then
fetches the released `dx-agents` and `dx-tools` snapshots pinned by tag and
commit SHA. The resources are installed under `/opt/dx`; `dx-mcp`, the Task
commands, and the `DX_*` environment variables remain available as before.

The Feature sets `GH_CONFIG_DIR` to `.devcontainer/.gh` through a bind mount.
Add `.devcontainer/.gh/` to the consuming repository's `.gitignore` and never
commit that directory: it contains local GitHub CLI authentication state.

## Maintenance

`renovate.json` extends the shared Gildraen preset. It updates the tagged
agent/tool snapshots, GitHub Actions pins, Dev Container Features, the pinned
Dev Container CLI used by tests, and the SHA-pinned `dx-tools` Taskfile include.

The remote Taskfile requires `github.com` to be trusted for each local Task
command:

```sh
TASK_REMOTE_TRUSTED_HOSTS=github.com task validate
TASK_REMOTE_TRUSTED_HOSTS=github.com task test
TASK_REMOTE_TRUSTED_HOSTS=github.com task feature:test
```

The root Taskfile includes the published `dx-tools` Taskfile for the
`tools:doctor` and `tools:mcp:github` commands.

Release Please requires the repository variable
`RELEASE_PLEASE_APP_CLIENT_ID` and secret `RELEASE_PLEASE_APP_PRIVATE_KEY`.
Feature publication remains disabled until `FEATURE_PUBLISH_ENABLED` is set
to `true`. Before enabling it, first disable or retarget the old publisher in
`Gildraen/dx`, then grant `Gildraen/dx-dev-feature` the Write role under
**Manage Actions access** for the existing `dx` Feature and collection
packages. The package is already public; if a new package is ever created,
GHCR makes it private by default and changing it to public is irreversible.
