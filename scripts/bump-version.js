#!/usr/bin/env node
// Bumps the version in plugins/tony/.claude-plugin/plugin.json.
// Usage: node scripts/bump-version.js [major|minor|patch]  (default: patch)

const fs = require("fs");
const path = require("path");

const PLUGIN_JSON = path.join(
  __dirname,
  "..",
  "plugins",
  "tony",
  ".claude-plugin",
  "plugin.json"
);

const bumpType = process.argv[2] || "patch";
if (!["major", "minor", "patch"].includes(bumpType)) {
  console.error(`Unknown bump type "${bumpType}". Use major, minor, or patch.`);
  process.exit(1);
}

const plugin = JSON.parse(fs.readFileSync(PLUGIN_JSON, "utf8"));
const [major, minor, patch] = plugin.version.split(".").map(Number);

let next;
if (bumpType === "major") next = `${major + 1}.0.0`;
else if (bumpType === "minor") next = `${major}.${minor + 1}.0`;
else next = `${major}.${minor}.${patch + 1}`;

plugin.version = next;
fs.writeFileSync(PLUGIN_JSON, JSON.stringify(plugin, null, 2) + "\n");

console.log(`plugin.json version: ${major}.${minor}.${patch} -> ${next}`);
