import { describe, it, expect } from "vitest";
import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { parse as parseYaml } from "yaml";
import { validateAlertGroup } from "../src/lib/alert-rule-validator/index";
import type { AlertGroup } from "../src/lib/alert-rule-validator/types";

const RULES_DIR = resolve(import.meta.dirname, "..", "src", "alert-rules");

function loadAlertFiles(): string[] {
  return readdirSync(RULES_DIR).filter((f) => f.endsWith(".yaml"));
}

describe("alert rule YAML files", () => {
  const files = loadAlertFiles();

  it("has at least one alert rule file", () => {
    expect(files.length).toBeGreaterThan(0);
  });

  it.each(files)("validates %s", (filename) => {
    const content = readFileSync(resolve(RULES_DIR, filename), "utf-8");
    const parsed = parseYaml(content);

    expect(parsed).toBeDefined();
    expect(parsed.groups).toBeDefined();
    expect(Array.isArray(parsed.groups)).toBe(true);

    for (const group of parsed.groups as AlertGroup[]) {
      const result = validateAlertGroup(group);
      if (!result.valid) {
        for (const err of result.errors) {
          console.error(`  [${err.rule}] ${err.message}`);
        }
      }
      expect(result.valid).toBe(true);
    }
  });
});
