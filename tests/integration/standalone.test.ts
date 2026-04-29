#!/usr/bin/env tsx
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { execSync } from "node:child_process";
import { resolve } from "node:path";
import { existsSync } from "node:fs";
const ROOT = resolve(import.meta.dirname, "..", "..");
const EXAMPLES = resolve(ROOT, "examples", "standalone");

const DOCKER_COMPOSE = resolve(EXAMPLES, "docker-compose.yml");

function run(
  cmd: string,
  cwd: string = ROOT,
): { stdout: string; stderr: string; success: boolean } {
  try {
    const stdout = execSync(cmd, {
      cwd,
      encoding: "utf-8",
      stdio: "pipe",
      timeout: 30_000,
    });
    return { stdout, stderr: "", success: true };
  } catch (err: unknown) {
    const e = err as { stdout?: string; stderr?: string };
    return { stdout: e.stdout ?? "", stderr: e.stderr ?? "", success: false };
  }
}

// Skip integration tests when Docker is not available
const DOCKER_AVAILABLE = run("docker info", ROOT).success;

describe.runIf(DOCKER_AVAILABLE)("integration: standalone", () => {
  beforeAll(() => {
    if (!existsSync(DOCKER_COMPOSE)) {
      throw new Error(`docker-compose.yml not found at ${DOCKER_COMPOSE}`);
    }
  }, 10_000);

  afterAll(() => {
    run("docker compose down --volumes", EXAMPLES);
  }, 30_000);

  it("starts the observability stack", () => {
    const result = run("docker compose up -d --wait", EXAMPLES);
    expect(result.success).toBe(true);
  }, 60_000);

  it("collector health check responds", async () => {
    await new Promise((r) => setTimeout(r, 5_000));
    const result = run("curl -s -o /dev/null -w '%{http_code}' http://localhost:13133");
    expect(result.stdout.trim()).toBe("200");
  }, 15_000);

  it("collector accepts OTLP over HTTP", () => {
    const result = run(
      `curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:4318/v1/traces -H 'Content-Type: application/json' -d '{"resourceSpans":[]}'`,
    );
    expect(result.stdout.trim()).toBe("200");
  }, 10_000);

  it("prometheus is reachable", async () => {
    await new Promise((r) => setTimeout(r, 2_000));
    const result = run("curl -s -o /dev/null -w '%{http_code}' http://localhost:9090/-/healthy");
    expect(result.stdout.trim()).toBe("200");
  }, 10_000);

  it("grafana is reachable", () => {
    const result = run("curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/health");
    expect(result.stdout.trim()).toBe("200");
  }, 10_000);
});
