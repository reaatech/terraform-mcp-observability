output "sns_topic_arn" {
  description = "SNS topic ARN for warning/high alert notifications"
  value       = local.create && var.enable_sns ? aws_sns_topic.alerts[0].arn : null
}

output "sns_topic_name" {
  description = "SNS topic name for warning/high alerts"
  value       = local.create && var.enable_sns ? aws_sns_topic.alerts[0].name : null
}

output "sns_critical_topic_arn" {
  description = "SNS topic ARN for critical alert notifications"
  value       = local.create && var.enable_sns ? aws_sns_topic.alerts_critical[0].arn : null
}

output "rule_group_namespaces" {
  description = "Map of created AMP rule group namespace names"
  value       = local.create ? keys(aws_prometheus_rule_group_namespace.this) : []
}
