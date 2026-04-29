# Skill: test-integration

## Description

Deploys the module to a local Kind cluster and validates end-to-end functionality using local metrics and trace backends.

## Inputs

| Input       | Type   | Required | Description                                    |
| ----------- | ------ | -------- | ---------------------------------------------- |
| `--backend` | string | yes      | Trace backend to test: `phoenix` or `langfuse` |

## Outputs

- Test report with pass/fail status
- Kind cluster is created for the test and destroyed afterward

## Execution

1. Verify prerequisites: `kind`, `kubectl`, `helm`, and `docker` are installed
2. Create a temporary Kind cluster with a unique name (e.g., `mcp-obs-test-<timestamp>`)
3. Deploy a local Prometheus instance (via Helm or static manifests) to act as the metrics backend
4. Deploy the OTel Collector Helm chart with:
   - OTLP receivers exposed via NodePort
   - Prometheus remote-write endpoint pointing to the local Prometheus
   - Trace exporters pointing to the selected backend
5. Deploy the specified trace backend (Phoenix or Langfuse) via Helm or manifests
6. Send synthetic OTel trace data to the collector:
   - Use `opentelemetry-js` or `curl` to POST OTLP spans
   - Include `gen_ai.operation.name`, `gen_ai.request.model`, and `mcp.tool.name` attributes
7. Verify traces appear in the trace backend UI or API
8. Verify metrics are scraped by the local Prometheus:
   - Query `up{job="otel-collector"}`
   - Query `gen_ai_client_operation_duration_count`
9. Verify Grafana dashboards load without JSON errors (deploy Grafana with dashboards mounted)
10. Destroy the Kind cluster
11. Output test report:
    ```
    Integration Test Report
    =======================
    Trace Backend:    <backend>   PASS
    Collector Health:            PASS
    Metrics Ingestion:           PASS
    Dashboard Load:              PASS
    ```

## Validation

A successful run exits with code 0 and all checks marked PASS.

## Notes

- **AWS Managed Prometheus is NOT validated in local integration tests** — it requires AWS credentials and a real workspace. AMP validation is handled separately via `terraform plan` dry-run in CI.
- If any step fails, print logs from the failing pod and exit non-zero.
- Use `trap` or equivalent cleanup to ensure the Kind cluster is always destroyed, even on failure.
