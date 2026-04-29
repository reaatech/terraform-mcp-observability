locals {
  create = var.create

  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "alerting"
  }

  tags = merge(local.default_tags, var.tags)

  sns_topic_arn = local.create && var.enable_sns ? aws_sns_topic.alerts[0].arn : null

  pagerduty_key = var.pagerduty_secret_name != "" ? data.aws_secretsmanager_secret_version.pagerduty[0].secret_string : var.pagerduty_routing_key
}

# ---------------------------------------------------------------------------
# PagerDuty Routing Key from Secrets Manager
# ---------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "pagerduty" {
  count = var.pagerduty_secret_name != "" ? 1 : 0

  secret_id = var.pagerduty_secret_name
}

# ---------------------------------------------------------------------------
# Slack Webhook URL from Secrets Manager
# ---------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "slack" {
  count = var.slack_secret_name != "" ? 1 : 0

  secret_id = var.slack_secret_name
}

# ---------------------------------------------------------------------------
# SNS Topics for Alert Notifications
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  count = local.create && var.enable_sns ? 1 : 0

  name = "${var.name}-alerts-${var.environment}"
  tags = local.tags
}

resource "aws_sns_topic" "alerts_critical" {
  count = local.create && var.enable_sns ? 1 : 0

  name = "${var.name}-alerts-critical-${var.environment}"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each = local.create && var.enable_sns ? toset(var.sns_email_endpoints) : toset([])

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "email_critical" {
  for_each = local.create && var.enable_sns ? toset(var.sns_critical_email_endpoints) : toset([])

  topic_arn = aws_sns_topic.alerts_critical[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "sms_critical" {
  for_each = local.create && var.enable_sns ? toset(var.sns_sms_endpoints) : toset([])

  topic_arn = aws_sns_topic.alerts_critical[0].arn
  protocol  = "sms"
  endpoint  = each.value
}

# ---------------------------------------------------------------------------
# AMP Alert Manager Definition
# ---------------------------------------------------------------------------
resource "aws_prometheus_alert_manager_definition" "this" {
  count = local.create && var.amp_workspace_id != "" && var.enable_sns ? 1 : 0

  workspace_id = var.amp_workspace_id

  definition = templatefile(
    "${path.module}/templates/alertmanager.tpl",
    {
      sns_topic_arn          = local.sns_topic_arn
      sns_critical_topic_arn = local.create && var.enable_sns ? aws_sns_topic.alerts_critical[0].arn : ""
      region                 = data.aws_region.current.id
      pagerduty_routing_key  = local.pagerduty_key
      pagerduty_enabled      = local.pagerduty_key != ""
      slack_api_url          = var.slack_secret_name != "" ? data.aws_secretsmanager_secret_version.slack[0].secret_string : var.slack_webhook_url
      slack_enabled          = var.slack_secret_name != "" || var.slack_webhook_url != ""
      slack_channel          = var.slack_channel
    }
  )
}

# ---------------------------------------------------------------------------
# AMP Rule Group Namespaces
# ---------------------------------------------------------------------------
resource "aws_prometheus_rule_group_namespace" "this" {
  for_each = local.create && var.amp_workspace_id != "" ? {
    for f in var.alert_rule_files : replace(basename(f), ".yaml", "") => file(f)
  } : {}

  name         = "${var.name}-${each.key}"
  workspace_id = var.amp_workspace_id
  data         = each.value
}

data "aws_region" "current" {}
