import { describe, it, expect } from "vitest";
import { validateAlertRule, validateAlertGroup, validatePromQL } from "./index";
import type { AlertRule, AlertGroup } from "./types";

const validRule: AlertRule = {
  alert: "TestAlert",
  expr: "rate(test_metric[5m]) > 0.5",
  for: "5m",
  labels: {
    severity: "warning",
    category: "performance",
  },
  annotations: {
    summary: "Test alert triggered",
    description: "A test alert for validation purposes.",
  },
};

describe("validatePromQL", () => {
  it("passes valid PromQL", () => {
    expect(validatePromQL("rate(test_metric[5m]) > 0.5")).toEqual([]);
  });

  it("rejects empty template variable", () => {
    const errors = validatePromQL("rate(metric{{ }}) > 0");
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0]).toContain("empty template");
  });

  it("rejects unbalanced parentheses", () => {
    const errors = validatePromQL("rate(test_metric[5m] > 0.5");
    expect(errors.some((e) => e.includes("unbalanced parentheses"))).toBe(true);
  });

  it("rejects unbalanced square brackets", () => {
    const errors = validatePromQL("rate(test_metric[5m) > 0.5");
    expect(errors.some((e) => e.includes("unbalanced square brackets"))).toBe(true);
  });

  it("warns when rate() is missing time range", () => {
    const errors = validatePromQL("rate(test_metric) > 0.5");
    expect(errors.some((e) => e.includes("time range"))).toBe(true);
  });
});

describe("validateAlertRule", () => {
  it("passes a valid rule", () => {
    const result = validateAlertRule(validRule);
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  it("rejects empty alert name", () => {
    const result = validateAlertRule({ ...validRule, alert: "" });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.message.includes("name"))).toBe(true);
  });

  it("rejects empty expression", () => {
    const result = validateAlertRule({ ...validRule, expr: "" });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.message.includes("expression"))).toBe(true);
  });

  it("rejects missing severity label", () => {
    const result = validateAlertRule({
      ...validRule,
      labels: { category: "performance" },
    });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.message.includes("severity"))).toBe(true);
  });

  it("rejects invalid severity value", () => {
    const result = validateAlertRule({
      ...validRule,
      labels: { severity: "urgent", category: "performance" },
    });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.message.includes("severity"))).toBe(true);
  });

  it("rejects missing summary annotation", () => {
    const result = validateAlertRule({
      ...validRule,
      annotations: { description: "no summary" },
    });
    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.message.includes("summary"))).toBe(true);
  });
});

describe("validateAlertGroup", () => {
  it("passes a valid group", () => {
    const group: AlertGroup = {
      name: "test-group",
      rules: [validRule],
    };
    const result = validateAlertGroup(group);
    expect(result.valid).toBe(true);
  });

  it("rejects empty group name", () => {
    const group: AlertGroup = {
      name: "",
      rules: [validRule],
    };
    const result = validateAlertGroup(group);
    expect(result.valid).toBe(false);
  });

  it("rejects group with no rules", () => {
    const group: AlertGroup = {
      name: "empty-group",
      rules: [],
    };
    const result = validateAlertGroup(group);
    expect(result.valid).toBe(false);
  });

  it("rejects group with invalid rule", () => {
    const group: AlertGroup = {
      name: "bad-group",
      rules: [{ ...validRule, alert: "" }],
    };
    const result = validateAlertGroup(group);
    expect(result.valid).toBe(false);
  });
});
