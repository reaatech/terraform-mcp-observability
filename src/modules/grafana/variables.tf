variable "create" {
  description = "Whether to create the Grafana resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for the Grafana deployment"
  type        = string
  default     = "mcp-grafana"
}

variable "namespace" {
  description = "Kubernetes namespace for Grafana"
  type        = string
  default     = "observability"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "helm_chart_version" {
  description = "Version of the Grafana Helm chart"
  type        = string
  default     = "8.5.0"
}

variable "replica_count" {
  description = "Number of Grafana replicas"
  type        = number
  default     = 1
}

variable "amp_workspace_endpoint" {
  description = "AWS Managed Prometheus query endpoint"
  type        = string
  default     = ""
}

variable "amp_region" {
  description = "AWS region of the AMP workspace (defaults to var.region or data.aws_region)"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region (defaults to data.aws_region)"
  type        = string
  default     = ""
}

variable "dashboard_files" {
  description = "List of dashboard JSON file paths to provision"
  type        = list(string)
  default     = []
}

variable "enable_ingress" {
  description = "Whether to create an ingress for Grafana"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Ingress host for Grafana"
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

variable "admin_password_secret_name" {
  description = "AWS Secrets Manager secret name for Grafana admin password"
  type        = string
  default     = ""
}

variable "create_irsa_role" {
  description = "Whether to use IRSA for the Grafana service account"
  type        = bool
  default     = false
}

variable "irsa_role_arn" {
  description = "IAM role ARN for the Grafana service account (IRSA)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
