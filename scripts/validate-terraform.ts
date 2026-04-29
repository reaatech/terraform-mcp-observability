#!/usr/bin/env tsx
/**
 * Runs terraform fmt -check and terraform validate across all module directories.
 *
 * For CI speed, set the Terraform plugin cache directory.
 * This avoids re-downloading providers for each sub-module:
 *
 *   export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
 *   mkdir -p "$TF_PLUGIN_CACHE_DIR"
 */
import { execSync } from "node:child_process";
import { readdirSync, statSync } from "node:fs";
import { resolve } from "node:path";

const rootDir = resolve(process.cwd(), "src", "modules");

function findTfDirs(dir: string): string[] {
  const results: string[] = [];
  try {
    const entries = readdirSync(dir);
    for (const entry of entries) {
      const fullPath = resolve(dir, entry);
      if (!statSync(fullPath).isDirectory()) continue;
      const children = readdirSync(fullPath);
      if (children.some((c) => c.endsWith(".tf"))) {
        results.push(fullPath);
      }
    }
  } catch {
    // Directory may not exist yet
  }
  return results;
}

let failed = false;

try {
  console.log("Running terraform fmt -check -recursive ...\n");
  execSync("terraform fmt -check -recursive", {
    stdio: "inherit",
    cwd: process.cwd(),
  });
} catch {
  failed = true;
}

const tfDirs = findTfDirs(rootDir).concat([process.cwd()]);

if (tfDirs.length === 0) {
  console.log("\nNo Terraform module directories found yet.");
} else {
  for (const dir of tfDirs) {
    console.log(`\nValidating ${dir} ...`);
    try {
      execSync("terraform init -backend=false", { stdio: "pipe", cwd: dir });
      execSync("terraform validate", { stdio: "inherit", cwd: dir });
    } catch {
      failed = true;
    }
  }
}

if (failed) {
  process.exit(1);
}

console.log("\nAll Terraform validations passed.");
