variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "trace_backend" {
  description = "Trace backend to deploy: phoenix, langfuse, or none"
  type        = string
  default     = "phoenix"

  validation {
    condition     = contains(["phoenix", "langfuse", "none"], var.trace_backend)
    error_message = "trace_backend must be one of: phoenix, langfuse, none."
  }
}

variable "enable_alerting" {
  description = "Whether to deploy alerting resources"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether to deploy logging resources"
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Whether to enable the metrics pipeline"
  type        = bool
  default     = true
}

variable "enable_traces" {
  description = "Whether to enable the traces pipeline"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for observability components"
  type        = string
  default     = "observability"
}

variable "create_irsa_role" {
  description = "Whether to create IAM roles for IRSA (collector remote write + Grafana query)"
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  type        = string
  default     = ""
}

variable "irsa_service_account_subjects" {
  description = "Service account subjects for the IRSA trust policy"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "AWS region for the observability stack (defaults to data.aws_region)"
  type        = string
  default     = ""
}

variable "langfuse_api_key_secret_name" {
  description = "Kubernetes secret name containing the Langfuse API key. Required when using Langfuse as trace backend."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
