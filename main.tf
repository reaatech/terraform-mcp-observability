locals {
  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "mcp-observability"
  }

  tags = merge(local.default_tags, var.tags)
}

data "aws_region" "current" {
  count = var.region == "" ? 1 : 0
}

locals {
  aws_region = var.region != "" ? var.region : one(data.aws_region.current[*].id)
}

# ---------------------------------------------------------------------------
# Logging (Phase 5)
# ---------------------------------------------------------------------------
module "logging" {
  source = "./src/modules/logging"

  create      = var.enable_logging
  name        = "mcp-logging"
  environment = var.environment
  log_groups = {
    "/mcp/observability/traces" = { retention_days = 14 }
    "/mcp/observability/agents" = { retention_days = 7 }
  }
  tags = local.tags
}

# ---------------------------------------------------------------------------
# Prometheus / AMP (Phase 3)
# ---------------------------------------------------------------------------
module "prometheus" {
  source = "./src/modules/prometheus"

  create                        = var.enable_metrics
  name                          = "mcp-prometheus"
  environment                   = var.environment
  alias                         = "${var.cluster_name}-${var.environment}"
  create_irsa_role              = var.create_irsa_role
  oidc_provider_arn             = var.oidc_provider_arn
  irsa_service_account_subjects = var.irsa_service_account_subjects
  tags                          = local.tags
}

# ---------------------------------------------------------------------------
# Trace Backend (Phase 2)
# ---------------------------------------------------------------------------
module "trace_backend" {
  source = "./src/modules/trace-backend"

  create        = var.trace_backend != "none"
  name          = "mcp-trace-backend"
  namespace     = var.namespace
  environment   = var.environment
  trace_backend = var.trace_backend
  tags          = local.tags
}

# ---------------------------------------------------------------------------
# Grafana (Phase 3)
# ---------------------------------------------------------------------------
module "grafana" {
  source = "./src/modules/grafana"

  create                 = var.enable_metrics
  name                   = "mcp-grafana"
  namespace              = var.namespace
  environment            = var.environment
  amp_workspace_endpoint = module.prometheus.prometheus_endpoint
  amp_region             = local.aws_region
  region                 = local.aws_region
  dashboard_files        = fileset("${path.module}/src/dashboards", "*.json")
  create_irsa_role       = var.create_irsa_role
  irsa_role_arn          = module.prometheus.query_role_arn
  tags                   = local.tags

  depends_on = [module.prometheus]
}

# ---------------------------------------------------------------------------
# OTel Collector (Phase 1)
# ---------------------------------------------------------------------------
module "otel_collector" {
  source = "./src/modules/otel-collector"

  create         = var.enable_metrics || var.enable_traces || var.enable_logging
  name           = "mcp-otel-collector"
  namespace      = var.namespace
  environment    = var.environment
  cluster_name   = var.cluster_name
  enable_metrics = var.enable_metrics
  enable_traces  = var.enable_traces
  enable_logs    = var.enable_logging
  metrics_endpoints = var.enable_metrics ? {
    amp = {
      endpoint = module.prometheus.remote_write_endpoint
      region   = local.aws_region
    }
  } : {}
  trace_endpoints = merge(
    var.trace_backend == "phoenix" ? {
      phoenix = {
        endpoint = module.trace_backend.otlp_http_endpoint
      }
    } : {},
    var.trace_backend == "langfuse" ? {
      langfuse = {
        endpoint = module.trace_backend.endpoint_url
      }
    } : {}
  )
  log_configuration = var.enable_logging ? {
    enabled        = true
    log_group_name = "/mcp/observability/collector"
    region         = local.aws_region
    retention_days = 7
    } : {
    enabled        = false
    log_group_name = ""
    region         = ""
    retention_days = 0
  }
  langfuse_api_key_secret_name = var.langfuse_api_key_secret_name
  tags                         = local.tags

  depends_on = [module.prometheus, module.trace_backend, module.logging]
}

# ---------------------------------------------------------------------------
# Alerting (Phase 4)
# ---------------------------------------------------------------------------
module "alerting" {
  source = "./src/modules/alerting"

  create           = var.enable_alerting && var.enable_metrics
  name             = "mcp-alerting"
  environment      = var.environment
  amp_workspace_id = module.prometheus.workspace_id
  alert_rule_files = fileset("${path.module}/src/alert-rules", "*.yaml")
  tags             = local.tags

  depends_on = [module.prometheus]
}
