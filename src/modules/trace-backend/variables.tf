variable "create" {
  description = "Whether to create the trace backend resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for the trace backend deployment"
  type        = string
  default     = "mcp-trace-backend"
}

variable "namespace" {
  description = "Kubernetes namespace for the trace backend"
  type        = string
  default     = "observability"
}

variable "environment" {
  description = "Environment name"
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

variable "phoenix_helm_chart_version" {
  description = "Helm chart version for Arize Phoenix"
  type        = string
  default     = "0.5.0"
}

variable "langfuse_helm_chart_version" {
  description = "Helm chart version for Langfuse"
  type        = string
  default     = "0.7.0"
}

variable "phoenix_replicas" {
  description = "Number of Phoenix replicas"
  type        = number
  default     = 1
}

variable "langfuse_web_replicas" {
  description = "Number of Langfuse web replicas"
  type        = number
  default     = 2
}

variable "create_database" {
  description = "Whether to create an RDS PostgreSQL database"
  type        = bool
  default     = false
}

variable "db_postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_storage_encrypted" {
  description = "Whether to encrypt RDS storage"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "mcp_observability"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "mcp_admin"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_vpc_security_group_ids" {
  description = "Security group IDs for the RDS instance"
  type        = list(string)
  default     = []
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
  default     = ""
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "create_redis" {
  description = "Whether to create an ElastiCache Redis cluster (for Langfuse)"
  type        = bool
  default     = false
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 1
}

variable "redis_subnet_group_name" {
  description = "Redis subnet group name"
  type        = string
  default     = ""
}

variable "redis_security_group_ids" {
  description = "Security group IDs for Redis"
  type        = list(string)
  default     = []
}

variable "enable_ingress" {
  description = "Whether to create an ingress for the trace backend UI"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Ingress host for the trace backend UI"
  type        = string
  default     = ""
}

variable "ingress_class" {
  description = "Ingress class to use"
  type        = string
  default     = "nginx"
}

variable "ingress_cert_issuer" {
  description = "cert-manager cluster issuer name"
  type        = string
  default     = "letsencrypt-prod"
}

variable "ingress_tls_enabled" {
  description = "Whether to enable TLS on the ingress"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
