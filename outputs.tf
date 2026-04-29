output "trace_backend_url" {
  description = "URL of the trace backend UI"
  value       = module.trace_backend.endpoint_url
}

output "trace_backend_type" {
  description = "Deployed trace backend type"
  value       = module.trace_backend.trace_backend_type
}

output "grafana_url" {
  description = "Grafana UI endpoint"
  value       = module.grafana.endpoint_url
}

output "prometheus_workspace_id" {
  description = "AWS Managed Prometheus workspace ID"
  value       = module.prometheus.workspace_id
}

output "prometheus_endpoint" {
  description = "AMP query endpoint"
  value       = module.prometheus.prometheus_endpoint
}

output "otlp_grpc_endpoint" {
  description = "OTLP gRPC endpoint for the collector"
  value       = module.otel_collector.otlp_grpc_endpoint
}

output "otlp_http_endpoint" {
  description = "OTLP HTTP endpoint for the collector"
  value       = module.otel_collector.otlp_http_endpoint
}

output "health_check_endpoint" {
  description = "Collector health check endpoint"
  value       = module.otel_collector.health_check_endpoint
}

output "alert_sns_topic_arn" {
  description = "SNS topic ARN for alert notifications"
  value       = module.alerting.sns_topic_arn
}

output "log_group_names" {
  description = "Set of CloudWatch log group names"
  value       = module.logging.log_group_names
}

output "log_group_arns" {
  description = "Map of CloudWatch log group names to ARNs"
  value       = module.logging.log_group_arns
}
