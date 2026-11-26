#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
mkdir -p "$workdir/feature" "$workdir/usr/local/bin"

for component in agents tools; do
	checkout="$workdir/upstream/$component"
	git init -q "$checkout"
	if [[ "$component" == agents ]]; then
		mkdir -p "$checkout/instructions" "$checkout/agents" "$checkout/skills"
		printf 'fixture agents\n' > "$checkout/AGENTS.md"
		for resource in instructions agents skills; do
			printf 'fixture resource\n' > "$checkout/$resource/fixture"
		done
	else
		mkdir -p "$checkout/bin" "$checkout/taskfiles"
		printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "fixture tools" "$@"' > "$checkout/bin/dx-mcp"
		chmod +x "$checkout/bin/dx-mcp"
		printf "version: '3'\n" > "$checkout/taskfiles/base.yml"
	fi
	git -C "$checkout" add .
	git -C "$checkout" -c user.name=dx-test -c user.email=dx-test@example.invalid -c commit.gpgsign=false commit -qm fixture
	git -C "$checkout" tag v1.2.3
done

agents_commit="$(git -C "$workdir/upstream/agents" rev-parse HEAD)"
tools_commit="$(git -C "$workdir/upstream/tools" rev-parse HEAD)"
node - "$repo_root/src/dx/install.sh" "$workdir/feature/install.sh" "$agents_commit" "$tools_commit" <<'EOF'
const fs = require('node:fs');
const [sourcePath, targetPath, agentsCommit, toolsCommit] = process.argv.slice(2);
let source = fs.readFileSync(sourcePath, 'utf8');
for (const [component, commit] of [['agents', agentsCommit], ['tools', toolsCommit]]) {
	const pattern = new RegExp(`(${component}_version=")[^"]+("\\n${component}_commit=")[^"]+(\")`);
  if (!pattern.test(source)) throw new Error(`pin pair not found for ${component}`);
  source = source.replace(pattern, `$1v1.2.3$2${commit}$3`);
}
fs.writeFileSync(targetPath, source);
EOF
cp "$repo_root/src/dx/dx-mcp" "$workdir/feature/dx-mcp"

export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_ALLOW_PROTOCOL=file
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0="url.file://$workdir/upstream/agents.insteadOf"
export GIT_CONFIG_VALUE_0=https://github.com/Gildraen/dx-agents.git
export GIT_CONFIG_KEY_1="url.file://$workdir/upstream/tools.insteadOf"
export GIT_CONFIG_VALUE_1=https://github.com/Gildraen/dx-tools.git
export DX_HOME="$workdir/installed"
export DX_BIN_DIR="$workdir/usr/local/bin"

bash "$workdir/feature/install.sh" > "$workdir/install.log" 2>&1 || { cat "$workdir/install.log" >&2; exit 1; }
test -f "$DX_HOME/components/agents/AGENTS.md"
test -x "$DX_HOME/components/tools/bin/dx-mcp"
for resource in AGENTS.md instructions agents skills; do
	test -L "$DX_HOME/$resource"
	[[ "$(readlink "$DX_HOME/$resource")" == "components/agents/$resource" ]]
	test -e "$DX_HOME/$resource"
done
for resource in bin taskfiles; do
	test -L "$DX_HOME/$resource"
	[[ "$(readlink "$DX_HOME/$resource")" == "components/tools/$resource" ]]
	test -e "$DX_HOME/$resource"
done
test ! -e "$DX_HOME/components/agents/.git"
test ! -e "$DX_HOME/components/tools/.git"
test -x "$DX_BIN_DIR/dx-mcp"
output="$(DX_TOOLS_HOME="$DX_HOME/components/tools" "$DX_BIN_DIR/dx-mcp" github --help)"
[[ "$output" == $'fixture tools\ngithub\n--help' ]]

write_variant() {
	local output="$1" field="$2" value="$3"
	node - "$workdir/feature/install.sh" "$output" "$field" "$value" <<'EOF'
const fs = require('node:fs');
const [sourcePath, targetPath, field, value] = process.argv.slice(2);
const source = fs.readFileSync(sourcePath, 'utf8');
const pattern = new RegExp(`^${field}="[^"]+"$`, 'm');
if (!pattern.test(source)) throw new Error(`installer field not found: ${field}`);
fs.writeFileSync(targetPath, source.replace(pattern, `${field}="${value}"`));
EOF
}

write_variant "$workdir/invalid-version.sh" agents_version invalid-ref
if DX_HOME="$workdir/invalid-version-install" DX_BIN_DIR="$DX_BIN_DIR" bash "$workdir/invalid-version.sh" > "$workdir/invalid.log" 2>&1; then
	printf 'Installer accepted an invalid version tag\n' >&2
	exit 1
fi
grep -Fq 'Invalid version tag for agents' "$workdir/invalid.log"

write_variant "$workdir/invalid-commit.sh" agents_commit invalid-ref
if DX_HOME="$workdir/invalid-commit-install" DX_BIN_DIR="$DX_BIN_DIR" bash "$workdir/invalid-commit.sh" > "$workdir/invalid.log" 2>&1; then
	printf 'Installer accepted an invalid commit SHA\n' >&2
	exit 1
fi
grep -Fq 'Invalid commit SHA for agents' "$workdir/invalid.log"

write_variant "$workdir/mismatched-pair.sh" agents_commit "$tools_commit"
if DX_HOME="$workdir/mismatched-install" DX_BIN_DIR="$DX_BIN_DIR" bash "$workdir/mismatched-pair.sh" > "$workdir/mismatch.log" 2>&1; then
	printf 'Installer accepted a tag and commit SHA that do not match\n' >&2
	exit 1
fi
grep -Fq 'does not match expected commit SHA' "$workdir/mismatch.log"

for component in agents tools; do
	printf 'stale\n' > "$DX_HOME/components/$component/stale"
done
bash "$workdir/feature/install.sh" > "$workdir/install.log" 2>&1
for component in agents tools; do
	if [[ -e "$DX_HOME/components/$component/stale" ]]; then
		printf 'Installer retained stale files in component: %s\n' "$component" >&2
		exit 1
	fi
done

printf 'Installer: snapshots, tag/SHA validation, links, launcher, replacement, and invalid refs pass\n'