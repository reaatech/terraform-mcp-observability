output "helm_release_name" {
  description = "Helm release name"
  value       = local.create ? helm_release.this[0].name : null
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = var.namespace
}

output "service_name" {
  description = "Grafana Kubernetes service name"
  value       = local.create ? "${helm_release.this[0].name}-grafana.${var.namespace}" : null
}

output "endpoint_url" {
  description = "Grafana UI endpoint"
  value       = local.create ? "http://${helm_release.this[0].name}-grafana.${var.namespace}:3000" : null
}
