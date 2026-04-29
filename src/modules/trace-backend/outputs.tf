output "trace_backend_type" {
  description = "The deployed trace backend type (phoenix, langfuse, or none)"
  value       = var.trace_backend
}

output "endpoint_url" {
  description = "URL of the trace backend UI"
  value = local.create ? (
    local.is_phoenix ? "http://${kubernetes_service_v1.phoenix[0].metadata[0].name}.${var.namespace}:6006" :
    local.is_langfuse ? "http://${kubernetes_service_v1.langfuse[0].metadata[0].name}.${var.namespace}:3000" :
    null
  ) : null
}

output "otlp_grpc_endpoint" {
  description = "OTLP gRPC endpoint for trace ingestion"
  value       = local.create && local.is_phoenix ? "http://${kubernetes_service_v1.phoenix[0].metadata[0].name}.${var.namespace}:4317" : null
}

output "otlp_http_endpoint" {
  description = "OTLP HTTP endpoint for trace ingestion"
  value       = local.create && local.is_phoenix ? "http://${kubernetes_service_v1.phoenix[0].metadata[0].name}.${var.namespace}:4318" : null
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value = local.create ? (
    local.is_phoenix ? helm_release.phoenix[0].name :
    local.is_langfuse ? helm_release.langfuse[0].name :
    null
  ) : null
}

output "namespace" {
  description = "Kubernetes namespace where the trace backend is deployed"
  value       = var.namespace
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = var.create_database ? aws_db_instance.postgres[0].endpoint : null
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for the database password"
  value       = var.create_database ? aws_secretsmanager_secret.db[0].arn : null
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = var.create_redis ? aws_elasticache_cluster.redis[0].cache_nodes[0].address : null
}
