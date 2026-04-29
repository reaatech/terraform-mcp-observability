import type { AlertRule, AlertGroup, ValidationResult, ValidationError } from "./types";

const REQUIRED_LABELS = ["severity", "category"];
const VALID_SEVERITIES = ["critical", "high", "warning", "info"];

export function validateAlertRule(rule: AlertRule): ValidationResult {
  const errors: ValidationError[] = [];

  if (!rule.alert || rule.alert.trim() === "") {
    errors.push({
      rule: rule.alert || "(unnamed)",
      message: "alert name is required",
    });
  }

  if (!rule.expr || rule.expr.trim() === "") {
    errors.push({
      rule: rule.alert,
      message: "PromQL expression is required",
    });
  } else {
    const exprErrors = validatePromQL(rule.expr);
    errors.push(...exprErrors.map((e) => ({ rule: rule.alert, message: e })));
  }

  for (const label of REQUIRED_LABELS) {
    if (!rule.labels[label]) {
      errors.push({
        rule: rule.alert,
        message: `label '${label}' is required`,
      });
    }
  }

  if (rule.labels.severity && !VALID_SEVERITIES.includes(rule.labels.severity)) {
    errors.push({
      rule: rule.alert,
      message: `severity '${rule.labels.severity}' must be one of: ${VALID_SEVERITIES.join(", ")}`,
    });
  }

  if (!rule.annotations.summary) {
    errors.push({
      rule: rule.alert,
      message: "annotation 'summary' is required",
    });
  }

  return { valid: errors.length === 0, errors };
}

export function validateAlertGroup(group: AlertGroup): ValidationResult {
  const errors: ValidationError[] = [];

  if (!group.name || group.name.trim() === "") {
    errors.push({ rule: "(group)", message: "group name is required" });
  }

  if (!group.rules || group.rules.length === 0) {
    errors.push({
      rule: group.name,
      message: "group must contain at least one rule",
    });
  } else {
    for (const rule of group.rules) {
      const result = validateAlertRule(rule);
      errors.push(...result.errors);
    }
  }

  return { valid: errors.length === 0, errors };
}

/**
 * Basic heuristic PromQL linter. This is NOT a full PromQL parser — it checks
 * common issues like unbalanced parentheses, empty template variables, and
 * missing rate() range selectors. Use promtool or a full parser for production
 * validation.
 */
export function validatePromQL(expr: string): string[] {
  const errors: string[] = [];

  if (expr.includes("{{ }}")) {
    errors.push("PromQL expression contains empty template variables");
  }

  const unbalanced = countChar(expr, "(") !== countChar(expr, ")");
  if (unbalanced) {
    errors.push("unbalanced parentheses in expression");
  }

  const squareUnbalanced = countChar(expr, "[") !== countChar(expr, "]");
  if (squareUnbalanced) {
    errors.push("unbalanced square brackets in expression");
  }

  const rateMatches = expr.matchAll(/rate\(([^)]+)\)/g);
  for (const match of rateMatches) {
    if (!/\[\d+[smhdw]\]/.test(match[1])) {
      errors.push("rate() requires a time range selector (e.g., [5m])");
    }
  }

  return errors;
}

function countChar(str: string, char: string): number {
  let count = 0;
  for (let i = 0; i < str.length; i++) {
    if (str[i] === char) count++;
  }
  return count;
}
