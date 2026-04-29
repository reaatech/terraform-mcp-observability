variable "create" {
  description = "Whether to create the Prometheus resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for the AMP workspace"
  type        = string
  default     = "mcp-prometheus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "alias" {
  description = "Alias for the AMP workspace"
  type        = string
  default     = ""
}

variable "create_vpc_endpoint" {
  description = "Whether to create a VPC endpoint for AMP"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for the AMP VPC endpoint"
  type        = string
  default     = ""
}

variable "vpc_endpoint_subnet_ids" {
  description = "Subnet IDs for the AMP VPC endpoint"
  type        = list(string)
  default     = []
}

variable "vpc_endpoint_security_group_ids" {
  description = "Security group IDs for the AMP VPC endpoint"
  type        = list(string)
  default     = []
}

variable "create_irsa_role" {
  description = "Whether to create IAM roles for IRSA (collector remote write + Grafana query)"
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA. Required when create_irsa_role is true."
  type        = string
  default     = ""
}

variable "irsa_service_account_subjects" {
  description = "Service account subjects for the IRSA trust policy (e.g., ['system:serviceaccount:observability:otel-collector'])"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}
