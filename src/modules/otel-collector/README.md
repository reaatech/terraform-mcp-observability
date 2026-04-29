# OTel Collector Module

Terraform module for deploying the OpenTelemetry Collector on Kubernetes via Helm.

## Usage

```hcl
module "otel_collector" {
  source = "./src/modules/otel-collector"

  name        = "mcp-otel-collector"
  namespace   = "observability"
  environment = "prod"
  cluster_name = "production"

  mode           = "deployment"
  replica_count  = 3

  metrics_endpoints = {
    amp = {
      endpoint = "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-xxx/api/v1/remote_write"
      region   = "us-east-1"
    }
  }

  trace_endpoints = {
    phoenix = {
      endpoint = "http://phoenix.observability:6006/v1/traces"
    }
  }

  log_configuration = {
    enabled        = true
    log_group_name = "/mcp/observability/collector"
    region         = "us-east-1"
    retention_days = 14
  }

  tags = {
    Team = "platform"
  }
}
```

## Requirements

| Name       | Version  |
| ---------- | -------- |
| terraform  | >= 1.5.7 |
| aws        | >= 6.28  |
| helm       | >= 2.11  |
| kubernetes | >= 2.23  |

## Inputs

| Name               | Description                    | Type        | Default            | Required |
| ------------------ | ------------------------------ | ----------- | ------------------ | -------- |
| create             | Whether to create resources    | bool        | true               | no       |
| name               | Name prefix for deployment     | string      | mcp-otel-collector | no       |
| namespace          | Kubernetes namespace           | string      | observability      | no       |
| environment        | Environment name               | string      | dev                | no       |
| cluster_name       | EKS cluster name               | string      | ""                 | no       |
| helm_chart_version | Helm chart version             | string      | 0.104.0            | no       |
| mode               | Deployment mode                | string      | deployment         | no       |
| replica_count      | Number of replicas             | number      | 2                  | no       |
| resources          | Resource requests/limits       | object      | see variables.tf   | no       |
| service_type       | Kubernetes service type        | string      | ClusterIP          | no       |
| enable_metrics     | Enable metrics pipeline        | bool        | true               | no       |
| enable_traces      | Enable traces pipeline         | bool        | true               | no       |
| enable_logs        | Enable logs pipeline           | bool        | true               | no       |
| metrics_endpoints  | Metrics remote write endpoints | object      | {}                 | no       |
| trace_endpoints    | Trace OTLP endpoints           | object      | {}                 | no       |
| log_configuration  | CloudWatch Logs config         | object      | see variables.tf   | no       |
| config_override    | Custom collector config YAML   | string      | ""                 | no       |
| tags               | Tags for AWS resources         | map(string) | {}                 | no       |

## Notes

- **Langfuse authentication**: When using `trace_endpoints.langfuse`, the collector config references the environment variable `LANGFUSE_API_KEY`. You must inject this into the collector pod, typically via a Kubernetes Secret and `extraEnv` in the Helm values. The Terraform-generated config uses the placeholder `${LANGFUSE_API_KEY}` which the collector runtime resolves from its environment.
- **Helm chart compatibility**: This module targets `opentelemetry-collector` Helm chart v0.104.0 from the [OpenTelemetry Helm charts repository](https://open-telemetry.github.io/opentelemetry-helm-charts). When upgrading the chart version, verify that the `config` values structure is compatible — chart versions may change the expected YAML layout.
- **HPA scale target**: The Horizontal Pod Autoscaler targets the Deployment by Helm release name. Depending on the Helm chart's naming conventions, the actual Kubernetes Deployment name may differ from the release name. Verify the scale target matches after deployment with `kubectl get hpa -n <namespace>`. If labels don't match, use `config_override` with a custom collector configuration or adjust the HPA outside this module.
- **Memory limiter alignment**: Set `memory_limiter_mib` and `memory_limiter_spike_mib` to values below the pod's memory limits in `resources.limits.memory` to avoid OOM kills. The default (512 MiB limit / 128 MiB spike) aligns with the default 1 Gi pod memory limit.

## Outputs

| Name                             | Description               |
| -------------------------------- | ------------------------- |
| helm_release_name                | Helm release name         |
| namespace                        | Kubernetes namespace      |
| otlp_grpc_endpoint               | OTLP gRPC endpoint        |
| otlp_http_endpoint               | OTLP HTTP endpoint        |
| health_check_endpoint            | Health check endpoint     |
| prometheus_self_metrics_endpoint | Self-metrics endpoint     |
| cloudwatch_log_group_name        | CloudWatch log group name |
| cloudwatch_log_group_arn         | CloudWatch log group ARN  |
