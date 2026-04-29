# ---------------------------------------------------------------------------
# Example: Complete Stack on EKS with Langfuse, AMP, and Managed Grafana
# ---------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# Configure for an existing EKS cluster. Point to your kubeconfig or use
# data sources / exec plugins for authentication.
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

module "mcp_observability" {
  source = "../../"

  cluster_name    = "production"
  environment     = "prod"
  trace_backend   = "langfuse"
  enable_alerting = true
  enable_logging  = true
  enable_metrics  = true
  enable_traces   = true

  namespace = "observability"

  tags = {
    Team        = "platform"
    CostCenter  = "engineering"
    Environment = "production"
  }
}

output "grafana_url" {
  value = module.mcp_observability.grafana_url
}

output "trace_backend_url" {
  value = module.mcp_observability.trace_backend_url
}

output "prometheus_workspace_id" {
  value = module.mcp_observability.prometheus_workspace_id
}
