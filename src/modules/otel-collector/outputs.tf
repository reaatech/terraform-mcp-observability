output "helm_release_name" {
  description = "Name of the Helm release"
  value       = local.create ? helm_release.this[0].name : null
}

output "namespace" {
  description = "Kubernetes namespace where the collector is deployed"
  value       = local.create ? kubernetes_namespace_v1.this[0].metadata[0].name : null
}

output "otlp_grpc_endpoint" {
  description = "OTLP gRPC endpoint for sending traces/metrics/logs"
  value       = local.create ? "${helm_release.this[0].name}-opentelemetry-collector.${var.namespace}:4317" : null
}

output "otlp_http_endpoint" {
  description = "OTLP HTTP endpoint for sending traces/metrics/logs"
  value       = local.create ? "${helm_release.this[0].name}-opentelemetry-collector.${var.namespace}:4318" : null
}

output "health_check_endpoint" {
  description = "Health check endpoint for the collector"
  value       = local.create ? "${helm_release.this[0].name}-opentelemetry-collector.${var.namespace}:13133" : null
}

output "prometheus_self_metrics_endpoint" {
  description = "Prometheus metrics endpoint for collector self-observability"
  value       = local.create ? "${helm_release.this[0].name}-opentelemetry-collector.${var.namespace}:8888" : null
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name (if logging is enabled)"
  value       = local.create && var.log_configuration.enabled ? aws_cloudwatch_log_group.this[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN (if logging is enabled)"
  value       = local.create && var.log_configuration.enabled ? aws_cloudwatch_log_group.this[0].arn : null
}
