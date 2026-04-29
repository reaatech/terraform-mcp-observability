# Skill: dashboard-json

## Description

Generates a Grafana dashboard JSON file with pre-configured panels for GenAI observability.

## Inputs

| Input           | Type   | Required | Description                                                                                                                        |
| --------------- | ------ | -------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `--name`        | string | yes      | Dashboard name (kebab-case, becomes filename)                                                                                      |
| `--description` | string | yes      | Dashboard description                                                                                                              |
| `--panels`      | string | no       | Comma-separated panel types: `latency-quantiles`, `token-usage`, `cost-by-model`, `error-rate`, `request-volume`, `quality-scores` |

## Outputs

- `src/dashboards/<name>.json` — Complete Grafana dashboard JSON (schema 36)

## Execution

1. Parse CLI arguments for name, description, panels
2. Generate Grafana dashboard JSON with:
   - `schemaVersion`: 36
   - `refresh`: `30s`
   - `time`: `{ from: "now-1h", to: "now" }`
   - `templating`: variables for `cluster`, `namespace`, `environment`, `model`
   - `annotations`: list with default annotation query
3. For each requested panel, generate a panel block:
   ```json
   {
     "id": 1,
     "title": "P95 Latency by Model",
     "type": "timeseries",
     "targets": [{
       "expr": "histogram_quantile(0.95, sum(rate(gen_ai_client_operation_duration_bucket{cluster=~\"$cluster\",namespace=~\"$namespace\"}[5m])) by (le, gen_ai_request_model))",
       "legendFormat": "{{gen_ai_request_model}}"
     }],
     "fieldConfig": { ... },
     "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 }
   }
   ```
4. Use AMP data source UID `prometheus` for all targets.
5. Add data links to trace backend for panels showing trace/span detail.
6. Write JSON to `src/dashboards/<name>.json`

## Validation

After generation, run:

```bash
node -e "JSON.parse(require('fs').readFileSync('src/dashboards/<name>.json'))"
```

Verify the file parses and contains `schemaVersion`, `panels`, and `templating`.

## Notes

- Color schemes: use consistent palette (e.g., green = healthy, red = error, yellow = warning).
- Panel IDs must be unique within the dashboard.
- Keep panel `gridPos` aligned in a 24-column grid (standard Grafana width).
