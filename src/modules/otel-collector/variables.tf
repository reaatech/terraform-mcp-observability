variable "create" {
  description = "Whether to create the OTel Collector resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for the OTel Collector deployment"
  type        = string
  default     = "mcp-otel-collector"
}

variable "namespace" {
  description = "Kubernetes namespace for the OTel Collector"
  type        = string
  default     = "observability"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name for tagging and resource identification"
  type        = string
  default     = ""
}

variable "helm_chart_version" {
  description = "Version of the OpenTelemetry Collector Helm chart"
  type        = string
  default     = "0.104.0"
}

variable "mode" {
  description = "Collector deployment mode: deployment, daemonset, or statefulset"
  type        = string
  default     = "deployment"

  validation {
    condition     = contains(["deployment", "daemonset", "statefulset"], var.mode)
    error_message = "Mode must be one of: deployment, daemonset, statefulset."
  }
}

variable "replica_count" {
  description = "Number of collector replicas (used only in deployment mode)"
  type        = number
  default     = 2
}

variable "resources" {
  description = "Resource requests and limits for collector pods"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "500m")
      memory = optional(string, "512Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "1000m")
      memory = optional(string, "1Gi")
    }), {})
  })
  default = {}
}

variable "service_type" {
  description = "Kubernetes service type for OTLP endpoints"
  type        = string
  default     = "ClusterIP"
}

variable "enable_metrics" {
  description = "Enable metrics pipeline"
  type        = bool
  default     = true
}

variable "enable_traces" {
  description = "Enable traces pipeline"
  type        = bool
  default     = true
}

variable "enable_logs" {
  description = "Enable logs pipeline"
  type        = bool
  default     = true
}

variable "metrics_endpoints" {
  description = "Remote write endpoints for metrics"
  type = object({
    amp = optional(object({
      endpoint = string
      region   = string
    }))
    prometheus = optional(object({
      endpoint = string
    }))
  })
  default = {}
}

variable "trace_endpoints" {
  description = "OTLP endpoints for trace exporters"
  type = object({
    phoenix = optional(object({
      endpoint = string
    }))
    langfuse = optional(object({
      endpoint = string
    }))
    xray = optional(object({
      region = string
    }))
  })
  default = {}
}

variable "log_configuration" {
  description = "CloudWatch Logs configuration"
  type = object({
    enabled        = optional(bool, false)
    log_group_name = optional(string, "/mcp/observability/collector")
    region         = optional(string, "us-east-1")
    retention_days = optional(number, 7)
  })
  default = {}
}

variable "memory_limiter_mib" {
  description = "Memory limiter soft limit in MiB for the collector (align with pod memory limits)"
  type        = number
  default     = 512
}

variable "memory_limiter_spike_mib" {
  description = "Memory limiter spike limit in MiB (should be ~25% of limit_mib)"
  type        = number
  default     = 128
}

variable "config_override" {
  description = "Override the generated collector config with custom YAML"
  type        = string
  default     = ""
}

variable "enable_hpa" {
  description = "Whether to create a HorizontalPodAutoscaler for the collector"
  type        = bool
  default     = false
}

variable "hpa_min_replicas" {
  description = "Minimum number of HPA replicas"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of HPA replicas"
  type        = number
  default     = 10
}

variable "hpa_target_cpu_utilization" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 70
}

variable "hpa_target_memory_utilization" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80
}

variable "enable_pdb" {
  description = "Whether to create a PodDisruptionBudget"
  type        = bool
  default     = false
}

variable "pdb_max_unavailable" {
  description = "Maximum number of unavailable pods during voluntary disruptions"
  type        = string
  default     = "1"
}

variable "enable_network_policies" {
  description = "Whether to create network policies restricting collector ingress"
  type        = bool
  default     = false
}

variable "agent_namespaces" {
  description = "List of Kubernetes namespaces allowed to send data to the collector"
  type        = list(string)
  default     = []
}

variable "recreate_pods_on_update" {
  description = "Whether to recreate collector pods when the Helm values change"
  type        = bool
  default     = false
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
