output "workspace_id" {
  description = "AMP workspace ID"
  value       = local.create ? aws_prometheus_workspace.this[0].id : null
}

output "workspace_arn" {
  description = "AMP workspace ARN"
  value       = local.create ? aws_prometheus_workspace.this[0].arn : null
}

output "workspace_alias" {
  description = "AMP workspace alias"
  value       = local.create ? aws_prometheus_workspace.this[0].alias : null
}

output "prometheus_endpoint" {
  description = "AMP query endpoint"
  value       = local.create ? "https://aps-workspaces.${data.aws_region.current.id}.amazonaws.com/workspaces/${aws_prometheus_workspace.this[0].id}/" : null
}

output "remote_write_endpoint" {
  description = "AMP remote write endpoint"
  value       = local.create ? "https://aps-workspaces.${data.aws_region.current.id}.amazonaws.com/workspaces/${aws_prometheus_workspace.this[0].id}/api/v1/remote_write" : null
}

output "remote_write_role_arn" {
  description = "IAM role ARN for collector remote write (IRSA)"
  value       = var.create_irsa_role ? aws_iam_role.remote_write[0].arn : null
}

output "query_role_arn" {
  description = "IAM role ARN for Grafana query (IRSA)"
  value       = var.create_irsa_role ? aws_iam_role.query[0].arn : null
}

output "vpc_endpoint_id" {
  description = "VPC endpoint ID for AMP"
  value       = var.create_vpc_endpoint ? aws_vpc_endpoint.amp[0].id : null
}
