variable "create" {
  description = "Whether to create the alerting resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for alerting resources"
  type        = string
  default     = "mcp-alerting"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "amp_workspace_id" {
  description = "AWS Managed Prometheus workspace ID"
  type        = string
  default     = ""
}

variable "alert_rule_files" {
  description = "List of alert rule YAML file paths to provision"
  type        = list(string)
  default     = []
}

variable "enable_sns" {
  description = "Whether to create SNS topics for alert notifications"
  type        = bool
  default     = true
}

variable "sns_email_endpoints" {
  description = "Email addresses to subscribe to warning/high alerts"
  type        = list(string)
  default     = []
}

variable "sns_critical_email_endpoints" {
  description = "Email addresses to subscribe to critical alerts"
  type        = list(string)
  default     = []
}

variable "sns_sms_endpoints" {
  description = "Phone numbers to subscribe to critical alerts via SMS"
  type        = list(string)
  default     = []
}

variable "pagerduty_routing_key" {
  description = "DEPRECATED: PagerDuty routing key for critical alerts (plaintext). Use pagerduty_secret_name instead."
  type        = string
  default     = ""

  validation {
    condition     = var.pagerduty_routing_key == "" || var.pagerduty_secret_name == ""
    error_message = "Cannot set both pagerduty_routing_key and pagerduty_secret_name. Use pagerduty_secret_name (recommended) or pagerduty_routing_key."
  }
}

variable "pagerduty_secret_name" {
  description = "AWS Secrets Manager secret name for PagerDuty routing key (recommended over plaintext)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "DEPRECATED: Slack webhook URL for alert notifications (plaintext). Use slack_secret_name instead."
  type        = string
  default     = ""

  validation {
    condition     = var.slack_webhook_url == "" || var.slack_secret_name == ""
    error_message = "Cannot set both slack_webhook_url and slack_secret_name. Use slack_secret_name (recommended) or slack_webhook_url."
  }
}

variable "slack_secret_name" {
  description = "AWS Secrets Manager secret name for Slack webhook URL (recommended over plaintext)"
  type        = string
  default     = ""
}

variable "slack_channel" {
  description = "Slack channel for alert notifications"
  type        = string
  default     = "#alerts-mcp"
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
