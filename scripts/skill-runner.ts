#!/usr/bin/env tsx
/**
 * Skill runner — reads and displays an AI agent skill definition.
 *
 * Usage:
 *   pnpm skill:<skill-name> -- [args...]
 *   tsx scripts/skill-runner.ts <skill-name> [args...]
 */
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const skillName = process.argv[2];

if (!skillName) {
  console.error("Usage: skill-runner.ts <skill-name> [args...]");
  console.error("\nAvailable skills:");
  const skills = [
    "terraform-module",
    "terraform-root",
    "dashboard-json",
    "alert-rules",
    "otel-config",
    "typescript-module",
    "prettier-eslint",
    "terraform-validate",
    "test-integration",
  ];
  skills.forEach((s) => console.error(`  - ${s}`));
  process.exit(1);
}

const skillPath = resolve(process.cwd(), "skills", skillName, "skills.md");

try {
  const content = readFileSync(skillPath, "utf-8");
  console.log(content);

  const args = process.argv.slice(3);
  if (args.length > 0) {
    console.log("\n---\nProvided arguments:", args.join(" "));
  }
} catch {
  console.error(`Skill "${skillName}" not found at ${skillPath}`);
  process.exit(1);
}
