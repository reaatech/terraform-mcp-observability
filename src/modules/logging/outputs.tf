output "log_group_names" {
  description = "Set of log group names"
  value       = local.create ? keys(aws_cloudwatch_log_group.this) : []
}

output "log_group_arns" {
  description = "Map of log group names to ARNs"
  value = local.create ? {
    for k, v in aws_cloudwatch_log_group.this : k => v.arn
  } : {}
}
