# Architecture: terraform-mcp-observability

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MCP Agent Systems                                  │
│                    (instrumented with OpenTelemetry SDK)                     │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │ OTLP (gRPC/HTTP)
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OTel Collector                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Receivers  │  │ Processors  │  │  Exporters  │  │    Extensions       │ │
│  │  - OTLP     │─▶│  - batch    │─▶│  - AMP      │  │  - health_check     │ │
│  │  - Prometheus│ │  - memory   │  │  - X-Ray    │  │  - prometheus       │ │
│  │  - hostmetrics││  - attributes│ │  - CW Logs  │  │  - pprof            │ │
│  └─────────────┘  │  - filter   │  │  - Phoenix  │  └─────────────────────┘ │
│                   │  - resource │  │  - Langfuse │                         │
│                   └─────────────┘  └─────────────┘                         │
└───────────────┬─────────────────────┬─────────────────────┬─────────────────┘
                │                     │                     │
                ▼                     ▼                     ▼
┌───────────────────────┐ ┌───────────────────────┐ ┌───────────────────────┐
│    Trace Backend      │ │   Metrics Backend     │ │    Log Backend        │
│  (Phoenix / Langfuse) │ │   (AWS Managed        │ │   (CloudWatch Logs    │
│                       │ │    Prometheus)        │ │    / Loki)            │
└───────────────────────┘ └───────────┬───────────┘ └───────────────────────┘
                                      │
                                      ▼
                            ┌───────────────────────┐
                            │   Alerting            │
                            │   (AMP Alertmanager   │
                            │    → SNS / PagerDuty) │
                            └───────────┬───────────┘
                                      │
                                      ▼
                            ┌───────────────────────┐
                            │   Visualization       │
                            │   (Grafana)           │
                            │   - 6 pre-built       │
                            │     dashboards        │
                            └───────────────────────┘
```

## Module Architecture

```
terraform-mcp-observability/
├── src/
│   ├── modules/
│   │   ├── otel-collector/       # OTel Collector deployment (K8s/ECS/Docker)
│   │   ├── trace-backend/        # Phoenix or Langfuse (selectable)
│   │   ├── prometheus/           # AWS Managed Prometheus workspace
│   │   ├── grafana/              # Grafana + dashboard provisioning
│   │   ├── alerting/             # Alert rules + Alertmanager
│   │   └── logging/              # CloudWatch Logs / Loki
│   ├── lib/                      # TypeScript utilities, validators, generators
│   ├── dashboards/               # 6 pre-built Grafana dashboard JSON files
│   ├── alert-rules/              # PromQL alerting rule YAML files
│   ├── otel-config/              # Collector config YAML templates
├── examples/
│   ├── complete/                 # Full EKS + Langfuse + AMP stack
│   ├── eks-integration/          # EKS addon pattern with Phoenix
│   └── standalone/               # Docker Compose local dev
└── tests/
    ├── unit/                     # TypeScript + YAML validation
    └── integration/              # Kind cluster deployment tests
```

## Data Flow

### Traces

1. MCP agents emit OTLP spans with `gen_ai` semantic conventions
2. OTel Collector receives via gRPC (4317) or HTTP (4318)
3. Spans are batched, enriched with `mcp.system`, `environment`, `cluster` attributes
4. Traces are exported to:
   - **Trace Backend** (Phoenix or Langfuse) for visualization and LLM-specific analysis
   - **AWS X-Ray** for AWS-native trace exploration
   - **CloudWatch Logs** for archival

### Metrics

1. OTel Collector scrapes Prometheus targets and receives OTLP metrics
2. Host/infrastructure metrics collected via `hostmetrics` receiver
3. LLM-specific metrics (token usage, cost, latency) extracted from span attributes
4. All metrics remote-written to AWS Managed Prometheus (AMP)
5. Grafana queries AMP as primary data source

### Logs

1. OTel Collector receives OTLP logs from instrumented applications
2. Logs are forwarded to CloudWatch Logs with structured attributes
3. Log groups organized by component: `/mcp/observability/traces`, `/mcp/observability/collector`
4. Retention policies applied per log group

## MCP Semantic Conventions

In addition to standard OpenTelemetry GenAI semantic conventions, spans emitted by MCP-based systems should include MCP-specific attributes for full observability:

| Attribute                 | Type   | Description                                                  |
| ------------------------- | ------ | ------------------------------------------------------------ |
| `mcp.system`              | string | System identifier (e.g., `agent-platform`)                   |
| `mcp.session.id`          | string | Unique session identifier for a multi-turn interaction       |
| `mcp.server.uri`          | string | MCP server endpoint (e.g., `http://tools.internal:8080/sse`) |
| `mcp.server.name`         | string | Human-readable server name                                   |
| `mcp.tool.name`           | string | Name of the tool being invoked                               |
| `mcp.tool.arguments_hash` | string | Hash of tool arguments for deduplication / cache analysis    |
| `mcp.tool.result_status`  | string | `success`, `error`, `timeout`, `rate_limited`                |
| `mcp.resource.uri`        | string | MCP resource URI being accessed                              |
| `mcp.prompt.name`         | string | Name of the prompt template used                             |

These attributes enable the **Agent/Tool** dashboard and MCP-specific alerts (tool failure rate, server connectivity).

## Key Design Decisions

### 1. Trace Backend: Pluggable Phoenix / Langfuse

| Aspect      | Phoenix                       | Langfuse                                            |
| ----------- | ----------------------------- | --------------------------------------------------- |
| Complexity  | Single container + PostgreSQL | Web + Worker + PostgreSQL + ClickHouse + Redis + S3 |
| Best for    | Small to medium deployments   | Enterprise scale with async processing              |
| OTel native | Yes (built on OpenInference)  | SDK + OTel support                                  |

Selected via `var.trace_backend` — only one is deployed at a time. Both expose the same OTLP interface.

### 2. AWS Managed Services as Defaults

- **AMP** over self-hosted Prometheus: no capacity planning, built-in HA, SigV4 auth
- **Managed Grafana** over self-hosted: no patching, built-in AMP integration
- **CloudWatch Logs** over self-hosted: no log storage management

Self-hosted alternatives (Prometheus on EKS, Grafana on EKS, Loki) are supported via feature flags.

### 3. Multi-Pipeline OTel Collector

Separate pipelines allow different processing for different data types:

```yaml
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes]
      exporters: [awsxray, otlphttp/phoenix]

    traces/llm:
      receivers: [otlp]
      processors: [memory_limiter, filter/llm-only, batch]
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

### 4. GenAI Semantic Conventions

All dashboards and alerts assume spans follow OpenTelemetry GenAI semantic conventions:

| Attribute                    | Description                             |
| ---------------------------- | --------------------------------------- |
| `gen_ai.operation.name`      | `chat`, `embeddings`, `text_completion` |
| `gen_ai.request.model`       | Model identifier (e.g., `gpt-4`)        |
| `gen_ai.usage.input_tokens`  | Prompt tokens                           |
| `gen_ai.usage.output_tokens` | Completion tokens                       |
| `gen_ai.usage.cached_tokens` | Cache hit tokens                        |
| `server.address`             | LLM provider endpoint                   |
| `error.type`                 | Error classification                    |

Cost is computed from token counts using configurable per-model pricing tables.

### 5. Dashboard Design Philosophy

Six dashboards, each answering a specific question:

| Dashboard           | Question Answered                            |
| ------------------- | -------------------------------------------- |
| **Overview**        | Is the system healthy right now?             |
| **LLM Performance** | How is each model performing?                |
| **Agent/Tool**      | Are tools and agent steps working correctly? |
| **Cost Analysis**   | Where is money being spent?                  |
| **Quality**         | How good are the LLM responses?              |
| **Infrastructure**  | Is the observability stack itself healthy?   |

All dashboards use **AMP as the primary metrics data source**, with template variables for `cluster`, `namespace`, `model`, and `environment`. Dashboard panels that display trace details or span-level data link out to the active trace backend UI (Phoenix or Langfuse) using data links. This keeps metrics in AMP (cost-efficient, long retention) and traces in the dedicated trace backend (rich span visualization).

### 6. Alerting Strategy

Four severity levels:

| Severity   | Channel                          | Response Time    |
| ---------- | -------------------------------- | ---------------- |
| `critical` | PagerDuty                        | Immediate        |
| `high`     | SNS (SMS + Email)                | < 1 hour         |
| `warning`  | SNS (Email)                      | < 1 business day |
| `info`     | No notification (dashboard only) | —                |

Alerts are grouped by `alertname` + `severity` with 5-minute group intervals and 4-hour repeat intervals.

## Deployment Prerequisites

Before applying this module, the following should be in place:

| Prerequisite            | Purpose                                      | Recommendation                                 |
| ----------------------- | -------------------------------------------- | ---------------------------------------------- |
| Terraform state backend | Remote state storage                         | S3 bucket + DynamoDB table for locking         |
| AWS credentials         | Provider authentication                      | Environment variables, SSO, or IAM role        |
| VPC / subnets           | Network placement for EKS/ECS resources      | Existing VPC with private subnets              |
| EKS cluster (optional)  | Kubernetes target for Helm-based deployments | Existing cluster or create via separate module |
| OIDC provider (EKS)     | IRSA setup                                   | EKS OIDC provider enabled for IRSA             |

The module accepts `create` flags for each component, so you can deploy into an existing cluster or create resources incrementally.

## Security Model

- **mTLS** between OTel Collector and backends (optional, enabled by default in production)
- **IRSA** (IAM Roles for Service Accounts) for EKS deployments — no static credentials
- **Secrets** stored in AWS Secrets Manager, referenced via `data "aws_secretsmanager_secret_version"`
- **Network isolation** via security groups — collector only accepts traffic from agent namespaces
- **Least privilege** IAM policies — AMP workspace access scoped to specific actions

## Scalability

| Component      | Scaling Strategy                                        |
| -------------- | ------------------------------------------------------- |
| OTel Collector | HPA on CPU/memory, max 10 replicas                      |
| AMP            | Automatic — no user action needed                       |
| Phoenix        | Vertical scaling (larger instances)                     |
| Langfuse       | HPA on Web, fixed Worker count, ClickHouse cluster mode |
| Grafana        | Vertical scaling (Managed Grafana handles this)         |

Default collector sizing: 2 replicas, 2 vCPU, 4Gi memory each — handles ~5K spans/sec.

## Cost Estimates (us-east-1, moderate usage)

> Last updated: 2026-04. Prices are estimates and vary by region, usage volume, and AWS pricing changes. Review current AWS pricing before budgeting.

| Component                          | Monthly Cost |
| ---------------------------------- | ------------ |
| AMP (100M samples)                 | ~$150        |
| Managed Grafana (10 users)         | ~$60         |
| CloudWatch Logs (50GB)             | ~$13         |
| X-Ray (1M traces)                  | ~$5          |
| Phoenix (t3.medium + RDS t3.small) | ~$80         |
| Langfuse (full stack)              | ~$400        |
| OTel Collector (2 × t3.medium)     | ~$60         |

**Total (Phoenix): ~$368/mo** | **Total (Langfuse): ~$688/mo**
