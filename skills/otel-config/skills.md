# Skill: otel-config

## Description

Generates OpenTelemetry Collector configuration YAML with multi-pipeline support.

## Inputs

| Input         | Type   | Required | Description                                                      |
| ------------- | ------ | -------- | ---------------------------------------------------------------- |
| `--name`      | string | yes      | Config name (e.g., `default`, `eks`, `ecs`)                      |
| `--pipelines` | string | no       | Comma-separated: `traces,metrics,logs,llm` (default: all)        |
| `--backends`  | string | no       | Comma-separated backends: `phoenix,langfuse,amp,xray,cloudwatch` |

## Outputs

- `src/otel-config/<name>.yaml` — Complete OTel Collector configuration

## Execution

1. Parse `--name`, `--pipelines`, `--backends`
2. Generate a **single-file** collector configuration (preferred over separate per-pipeline files):

   ```yaml
   receivers:
     otlp:
       protocols:
         grpc:
           endpoint: 0.0.0.0:4317
         http:
           endpoint: 0.0.0.0:4318
     prometheus:
       config:
         scrape_configs:
           - job_name: otel-collector
             static_configs:
               - targets: [localhost:8888]
     hostmetrics:
       collection_interval: 30s
       scrapers:
         cpu: {}
         memory: {}
         disk: {}
         load: {}

   processors:
     memory_limiter:
       limit_mib: 512
       spike_limit_mib: 128
     batch:
       timeout: 1s
       send_batch_size: 1024
     resource:
       attributes:
         - key: environment
           value: ${ENV}
           action: upsert
     attributes/enrich:
       actions:
         - key: mcp.system
           value: ${MCP_SYSTEM}
           action: upsert

   exporters:
     prometheusremotewrite:
       endpoint: ${AMP_ENDPOINT}
       auth:
         authenticator: sigv4auth
     awsxray:
       region: ${AWS_REGION}
     awscloudwatchlogs:
       log_group_name: /mcp/observability/collector
       log_stream_name: otel-collector
     otlphttp/phoenix:
       endpoint: ${PHOENIX_ENDPOINT}
     otlphttp/langfuse:
       endpoint: ${LANGFUSE_ENDPOINT}
       headers:
         Authorization: ${LANGFUSE_API_KEY}

   extensions:
     health_check:
       endpoint: 0.0.0.0:13133
     pprof:
       endpoint: 0.0.0.0:1777
     prometheus:
       endpoint: 0.0.0.0:8888

   service:
     extensions: [health_check, pprof, prometheus]
     pipelines:
       traces:
         receivers: [otlp]
         processors: [memory_limiter, batch, resource]
         exporters: [awsxray, otlphttp/phoenix]
       traces/llm:
         receivers: [otlp]
         processors: [memory_limiter, batch, resource]
         exporters: [otlphttp/langfuse]
       metrics:
         receivers: [otlp, prometheus, hostmetrics]
         processors: [memory_limiter, batch, resource]
         exporters: [prometheusremotewrite]
       logs:
         receivers: [otlp]
         processors: [memory_limiter, batch]
         exporters: [awscloudwatchlogs]
   ```

3. Only include receivers, processors, exporters, and pipelines relevant to the requested `--pipelines` and `--backends`.
4. Use `${ENV_VAR}` notation for all secrets and environment-specific values.
5. Write YAML to `src/otel-config/<name>.yaml`

## Validation

After generation, run:

```bash
# Basic YAML parse check
node -e "require('fs').readFileSync('src/otel-config/<name>.yaml', 'utf8')"

# If the collector binary is available:
opentelemetry-collector validate --config src/otel-config/<name>.yaml
```

## Notes

- Prefer a single config file with multiple pipelines over separate files. The root module will mount this as a ConfigMap or equivalent.
- The `traces/llm` pipeline is used when both a general trace backend and Langfuse are configured simultaneously.
- `memory_limiter` should be the first processor in every pipeline.
