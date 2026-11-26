import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const manifest = JSON.parse(
  await readFile("src/dev-prerequisites/devcontainer-feature.json", "utf8"),
);

assert.equal(manifest.id, "dev-prerequisites");
assert.equal(manifest.version, "1.0.0");
assert.deepEqual(manifest.dependsOn, {
  "ghcr.io/devcontainers/features/github-cli:1": {},
  "ghcr.io/devcontainers-extra/features/go-task:1": {
    version: "3.53.1",
  },
  "ghcr.io/devcontainers-extra/features/apt-get-packages:1": {
    packages: "git",
  },
});

for (const key of ["options", "containerEnv", "mounts", "customizations"]) {
  assert.equal(key in manifest, false, `Unexpected manifest property: ${key}`);
}