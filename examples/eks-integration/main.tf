# ---------------------------------------------------------------------------
# Example: EKS Integration with OTel Collector Addon and Phoenix
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

  cluster_name    = "staging"
  environment     = "staging"
  trace_backend   = "phoenix"
  enable_alerting = true
  enable_logging  = true
  enable_metrics  = true
  enable_traces   = true

  namespace = "observability"

  tags = {
    Team        = "platform"
    Environment = "staging"
  }
}

output "otlp_grpc_endpoint" {
  value = module.mcp_observability.otlp_grpc_endpoint
}

output "otlp_http_endpoint" {
  value = module.mcp_observability.otlp_http_endpoint
}
