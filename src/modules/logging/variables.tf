variable "create" {
  description = "Whether to create the logging resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for logging resources"
  type        = string
  default     = "mcp-logging"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "log_groups" {
  description = "Map of log group names to retention configurations"
  type = map(object({
    retention_days = optional(number, 7)
    kms_key_id     = optional(string, null)
  }))
  default = {
    "/mcp/observability/collector" = { retention_days = 7 }
    "/mcp/observability/traces"    = { retention_days = 14 }
    "/mcp/observability/agents"    = { retention_days = 7 }
  }
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
