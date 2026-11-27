import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const readJson = async (path) => JSON.parse(await readFile(path, "utf8"));
const feature = await readJson("src/dx/devcontainer-feature.json");
const renovate = await readJson("renovate.json");
const releaseConfig = await readJson("release-please-config.json");
const releaseManifest = await readJson(".release-please-manifest.json");
const version = (await readFile("version.txt", "utf8")).trim();
const install = await readFile("src/dx/install.sh", "utf8");
const taskfile = await readFile("Taskfile.yml", "utf8");
const featureTest = await readFile("scripts/feature-test.sh", "utf8");
const readme = await readFile("README.md", "utf8");
const releaseWorkflow = await readFile(".github/workflows/release.yaml", "utf8");
const releasePleaseWorkflow = await readFile(
  ".github/workflows/release-please.yaml",
  "utf8",
);
const semverPattern = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

assert.equal(feature.id, "dx");
assert.match(feature.version, semverPattern);
assert.equal(feature.version, version);
assert.equal(feature.version, releaseManifest["."]);
assert.deepEqual(feature.options, {});
const getDependency = (pattern) => {
  const entry = Object.entries(feature.dependsOn).find(([name]) => pattern.test(name));
  assert.ok(entry, `Missing dependency matching ${pattern}`);
  return entry[1];
};
assert.deepEqual(
  getDependency(/^ghcr\.io\/devcontainers\/features\/node:[^/]+$/),
  { version: "lts" },
);
assert.deepEqual(
  getDependency(/^ghcr\.io\/devcontainers\/features\/github-cli:[^/]+$/),
  {},
);
assert.deepEqual(
  getDependency(/^ghcr\.io\/devcontainers-extra\/features\/go-task:[^/]+$/),
  { version: "3.53.1" },
);
assert.deepEqual(
  getDependency(/^ghcr\.io\/devcontainers-extra\/features\/apt-get-packages:[^/]+$/),
  { packages: "git,jq,ripgrep,libatomic1" },
);
assert.deepEqual(feature.containerEnv, {
  DX_HOME: "/opt/dx",
  DX_AGENTS_HOME: "/opt/dx/components/agents",
  DX_TOOLS_HOME: "/opt/dx/components/tools",
  GH_CONFIG_DIR: "/var/lib/dx/devcontainer/.gh",
});
assert.deepEqual(feature.mounts, [
  {
    source: "${localWorkspaceFolder}/.devcontainer",
    target: "/var/lib/dx/devcontainer",
    type: "bind",
  },
]);

for (const component of ["agents", "tools"]) {
  const depName = `.devcontainer/components/${component}`;
  const pattern = new RegExp(
    `# renovate: datasource=github-tags depName=${depName} packageName=Gildraen/dx-${component}\\n${component}_version="v?${semverPattern.source.slice(1, -1)}"\\n${component}_commit="([0-9a-f]{40})"`,
  );
  assert.ok(pattern.test(install), `Missing Renovate-managed tag/SHA pair for ${component}`);
}

assert.equal(renovate.extends.length, 1);
assert.match(
  renovate.extends[0],
  /^github>Gildraen\/renovate-config#\d+\.\d+\.\d+$/,
);
const cliManager = renovate.customManagers.find((manager) =>
  manager.matchStrings.some((matchString) => matchString.includes("@devcontainers/cli")),
);
assert.ok(cliManager, "Missing Renovate manager for the Dev Container CLI pin");
assert.equal(cliManager.datasourceTemplate, "npm");
const cliVersion = new RegExp(cliManager.matchStrings[0]).exec(featureTest)?.groups.currentValue;
assert.match(cliVersion, semverPattern);
assert.match(
  taskfile,
  /https:\/\/github\.com\/Gildraen\/dx-tools\/raw\/[0-9a-f]{40}\/taskfiles\/base\.yml\s+# v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:[-+][0-9A-Za-z.+-]+)?/,
);
assert.equal(releaseConfig["include-v-in-tag"], false);
assert.match(releaseConfig["bootstrap-sha"], /^[0-9a-f]{40}$/);
assert.equal(releaseConfig.packages["."]["package-name"], "dx");
assert.equal(releaseConfig.packages["."]["version-file"], "version.txt");
assert.deepEqual(releaseConfig.packages["."]["extra-files"], [
  {
    type: "json",
    path: "src/dx/devcontainer-feature.json",
    jsonpath: "$.version",
  },
]);
assert.match(releaseWorkflow, /on:\n  release:\n    types:\n      - published/);
assert.doesNotMatch(releaseWorkflow, /FEATURE_PUBLISH_ENABLED/);
assert.match(releaseWorkflow, /test "\$RELEASE_TAG" = "\$feature_version"/);
assert.match(releaseWorkflow, /features-namespace: "gildraen\/dx"/);
assert.match(releasePleaseWorkflow, /RELEASE_PLEASE_APP_CLIENT_ID/);
assert.match(releasePleaseWorkflow, /RELEASE_PLEASE_APP_PRIVATE_KEY/);
assert.match(releasePleaseWorkflow, /reusable-release-please\.yml@[0-9a-f]{40} # 0\.2\.0/);
assert.ok(readme.includes("ghcr.io/gildraen/dx/dx:1"));
assert.ok(readme.includes("Manage Actions access"));