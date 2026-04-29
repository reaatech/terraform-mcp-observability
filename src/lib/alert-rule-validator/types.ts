export interface AlertRule {
  alert: string;
  expr: string;
  for?: string;
  labels: Record<string, string>;
  annotations: Record<string, string>;
}

export interface AlertGroup {
  name: string;
  interval?: string;
  rules: AlertRule[];
}

export interface ValidationError {
  rule: string;
  message: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}
