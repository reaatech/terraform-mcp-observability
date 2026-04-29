# Skill: alert-rules

## Description

Generates PromQL alerting rules in YAML format for AWS Managed Prometheus.

## Inputs

| Input        | Type   | Required | Description                                                                |
| ------------ | ------ | -------- | -------------------------------------------------------------------------- |
| `--category` | string | yes      | Alert category: `availability`, `performance`, `llm`, `cost`, `resilience` |

## Outputs

- `src/alert-rules/<category>.yaml` — PromQL alerting rules in AMP rule group format

## Execution

1. Parse CLI argument for category
2. Generate YAML with AMP rule group namespace format:
   ```yaml
   groups:
     - name: mcp-observability-<category>
       interval: 30s
       rules:
         - alert: <AlertName>
           expr: <PromQL expression>
           for: 5m
           labels:
             severity: <critical|high|warning|info>
             category: <category>
           annotations:
             summary: <short description>
             description: <long description with runbook link>
   ```
3. Category-specific rules:
   - **availability**: `OTelCollectorDown`, `HighErrorRate`
   - **performance**: `HighLatencyP95`, `LatencySpike`
   - **llm**: `HighTokenUsage`, `RateLimitEvents`, `ModelErrorRate`
   - **cost**: `HighCostRate`, `CostAnomaly`
   - **resilience**: `CircuitBreakerOpen`, `HighQueueDepth`
4. Each PromQL expression should:
   - Use `rate()` or `increase()` where appropriate
   - Include `cluster` and `namespace` label selectors
   - Reference `gen_ai_*` or `mcp_*` metric names per project conventions
5. Write YAML to `src/alert-rules/<category>.yaml`

## Validation

After generation, run:

```bash
# Basic YAML parse check
node -e "require('fs').readFileSync('src/alert-rules/<category>.yaml', 'utf8')"

# If promtool is available:
promtool check rules src/alert-rules/<category>.yaml
```

## Notes

- `for` duration should be 5m for most alerts, 1m for critical availability alerts.
- Severity mapping: `critical` → PagerDuty, `high` → SNS SMS+Email, `warning` → SNS Email, `info` → dashboard only.
- Include a `runbook_url` annotation pointing to `docs/alerts.md#<alert-name>`.
