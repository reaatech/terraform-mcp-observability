# terraform-mcp-observability

Drop-in Terraform module that deploys a complete observability stack for MCP-based agent systems.

One `terraform apply` delivers:

- **Trace visualization** — Arize Phoenix or Langfuse (selectable)
- **Metrics** — AWS Managed Prometheus with pre-built GenAI dashboards
- **Alerting** — PromQL rules for latency, errors, cost anomalies, circuit breakers
- **Log aggregation** — CloudWatch Logs with structured OTel forwarding

Pre-wired to consume OpenTelemetry output from your instrumented agent stack.

## Quick Start

```hcl
module "mcp_observability" {
  source = "github.com/reaatech/terraform-mcp-observability"

  cluster_name   = "production"
  environment    = "prod"
  trace_backend  = "phoenix" # or "langfuse"
  enable_alerting = true
  enable_logging  = true
}
```

## Documentation

- [Architecture](./ARCHITECTURE.md) — System design, data flow, and conventions
- [Development Plan](./DEV_PLAN.md) — Roadmap and phase breakdown
- [Contributing](./CONTRIBUTING.md) — Setup, conventions, and PR workflow
- [Security](./SECURITY.md) — Vulnerability reporting and best practices
- [Code of Conduct](./CODE_OF_CONDUCT.md) — Community standards
- [Agent Skills](./AGENTS.md) — AI-assisted development workflows
- [Changelog](./CHANGELOG.md) — Version history and release notes

## Requirements

- Terraform >= 1.5.7
- AWS Provider >= 6.28
- Helm Provider >= 2.11
- Kubernetes Provider >= 2.23
- Node.js >= 21 (for development tooling)
- pnpm >= 9

## Inputs

| Name                          | Description                                       | Type         | Default           | Required |
| ----------------------------- | ------------------------------------------------- | ------------ | ----------------- | -------- |
| cluster_name                  | EKS cluster name                                  | string       | —                 | yes      |
| environment                   | Environment name (dev, staging, prod)             | string       | `"dev"`           | no       |
| trace_backend                 | Trace backend: phoenix, langfuse, or none         | string       | `"phoenix"`       | no       |
| enable_alerting               | Whether to deploy alerting resources              | bool         | `true`            | no       |
| enable_logging                | Whether to deploy logging resources               | bool         | `true`            | no       |
| enable_metrics                | Whether to enable the metrics pipeline            | bool         | `true`            | no       |
| enable_traces                 | Whether to enable the traces pipeline             | bool         | `true`            | no       |
| namespace                     | Kubernetes namespace for observability components | string       | `"observability"` | no       |
| create_irsa_role              | Whether to create IAM roles for IRSA              | bool         | `false`           | no       |
| oidc_provider_arn             | ARN of the OIDC provider for IRSA                 | string       | `""`              | no       |
| irsa_service_account_subjects | Service account subjects for IRSA trust policy    | list(string) | `[]`              | no       |
| region                        | AWS region (defaults to data.aws_region)          | string       | `""`              | no       |
| langfuse_api_key_secret_name  | K8s secret name containing the Langfuse API key   | string       | `""`              | no       |
| tags                          | Tags to apply to all AWS resources                | map(string)  | `{}`              | no       |

## Outputs

| Name                    | Description                               |
| ----------------------- | ----------------------------------------- |
| trace_backend_url       | URL of the trace backend UI               |
| trace_backend_type      | Deployed trace backend type               |
| grafana_url             | Grafana UI endpoint                       |
| prometheus_workspace_id | AWS Managed Prometheus workspace ID       |
| prometheus_endpoint     | AMP query endpoint                        |
| otlp_grpc_endpoint      | OTLP gRPC endpoint for the collector      |
| otlp_http_endpoint      | OTLP HTTP endpoint for the collector      |
| health_check_endpoint   | Collector health check endpoint           |
| alert_sns_topic_arn     | SNS topic ARN for alert notifications     |
| log_group_names         | Set of CloudWatch log group names         |
| log_group_arns          | Map of CloudWatch log group names to ARNs |

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## License

MIT
