#!/usr/bin/env bash
set -euo pipefail

DX_HOME="${DX_HOME:-/opt/dx}"
DX_BIN_DIR="${DX_BIN_DIR:-/usr/local/bin}"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# renovate: datasource=github-tags depName=.devcontainer/components/agents packageName=Gildraen/dx-agents
agents_version="0.3.0"
agents_commit="b61d5030978de234c6c6623715c27cba0c3e2381"
# renovate: datasource=github-tags depName=.devcontainer/components/tools packageName=Gildraen/dx-tools
tools_version="0.2.0"
tools_commit="340e66482239419544ed405079bce4e8395dbc6e"
download_root="$(mktemp -d)"
trap 'rm -rf "$download_root"' EXIT

install_component() {
	local name="$1" version="$2" commit="$3" resolved_commit
	local checkout="$download_root/$name"
	if [[ ! "$version" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
		printf 'Invalid version tag for %s: %s\n' "$name" "$version" >&2
		return 1
	fi
	if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
		printf 'Invalid commit SHA for %s: %s\n' "$name" "$commit" >&2
		return 1
	fi
	git init -q "$checkout"
	git -C "$checkout" remote add origin "https://github.com/Gildraen/dx-$name.git"
	GIT_TERMINAL_PROMPT=0 git -C "$checkout" fetch --depth=1 origin "$version"
	resolved_commit="$(git -C "$checkout" rev-parse --verify 'FETCH_HEAD^{commit}')"
	if [[ "$resolved_commit" != "$commit" ]]; then
		printf 'Tag %s for %s resolves to %s, which does not match expected commit SHA %s\n' "$version" "$name" "$resolved_commit" "$commit" >&2
		return 1
	fi
	git -C "$checkout" checkout -q --detach "$commit"
	rm -rf "$checkout/.git"
	rm -rf "$DX_HOME/components/$name"
	mkdir -p "$DX_HOME/components/$name"
	cp -R "$checkout/." "$DX_HOME/components/$name/"
}

install_component agents "$agents_version" "$agents_commit"
install_component tools "$tools_version" "$tools_commit"
test -f "$DX_HOME/components/agents/AGENTS.md"
test -x "$DX_HOME/components/tools/bin/dx-mcp"

for resource in AGENTS.md instructions agents skills; do
	rm -rf "$DX_HOME/$resource"
	ln -s "components/agents/$resource" "$DX_HOME/$resource"
done
for resource in bin taskfiles; do
	rm -rf "$DX_HOME/$resource"
	ln -s "components/tools/$resource" "$DX_HOME/$resource"
done
install -D -m 0755 "$FEATURE_DIR/dx-mcp" "$DX_BIN_DIR/dx-mcp"

echo "dx components installed at $DX_HOME/components"