locals {
  create = var.create

  default_tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
    ManagedBy   = "terraform"
    Module      = "otel-collector"
  }

  tags = merge(local.default_tags, var.tags)

  # Build collector config from inputs unless overridden
  collector_config = var.config_override != "" ? var.config_override : templatefile(
    "${path.module}/templates/collector-config.yaml.tpl",
    {
      environment        = var.environment
      cluster_name       = var.cluster_name
      enable_metrics     = var.enable_metrics
      enable_traces      = var.enable_traces
      enable_logs        = var.enable_logs
      metrics_amp        = try(var.metrics_endpoints.amp, null)
      metrics_prom       = try(var.metrics_endpoints.prometheus, null)
      traces_phoenix     = try(var.trace_endpoints.phoenix, null)
      traces_langfuse    = try(var.trace_endpoints.langfuse, null)
      traces_xray        = try(var.trace_endpoints.xray, null)
      logs_enabled       = var.log_configuration.enabled
      logs_group         = var.log_configuration.log_group_name
      logs_region        = var.log_configuration.region
      memory_limiter_mib = var.memory_limiter_mib
      memory_spike_mib   = var.memory_limiter_spike_mib
    }
  )
}

# Namespace for observability components
resource "kubernetes_namespace_v1" "this" {
  count = local.create ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Helm release for OpenTelemetry Collector
resource "helm_release" "this" {
  count = local.create ? 1 : 0

  name       = var.name
  namespace  = kubernetes_namespace_v1.this[0].metadata[0].name
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = var.helm_chart_version

  set = [
    {
      name  = "mode"
      value = var.mode
    },
    {
      name  = "replicaCount"
      value = var.mode == "deployment" ? var.replica_count : 1
    },
    {
      name  = "service.type"
      value = var.service_type
    },
    {
      name  = "resources.requests.cpu"
      value = try(var.resources.requests.cpu, "500m")
    },
    {
      name  = "resources.requests.memory"
      value = try(var.resources.requests.memory, "512Mi")
    },
    {
      name  = "resources.limits.cpu"
      value = try(var.resources.limits.cpu, "1000m")
    },
    {
      name  = "resources.limits.memory"
      value = try(var.resources.limits.memory, "1Gi")
    }
  ]

  # ConfigMap values for collector configuration
  values = [
    yamlencode(merge(
      {
        config = yamldecode(local.collector_config)
      },
      var.langfuse_api_key_secret_name != "" ? {
        extraEnvs = [
          {
            name = "LANGFUSE_API_KEY"
            valueFrom = {
              secretKeyRef = {
                name = var.langfuse_api_key_secret_name
                key  = "api_key"
              }
            }
          }
        ]
      } : {}
    ))
  ]

  recreate_pods = var.recreate_pods_on_update

  depends_on = [kubernetes_namespace_v1.this]
}

# ---------------------------------------------------------------------------
# Horizontal Pod Autoscaler
# ---------------------------------------------------------------------------
resource "kubernetes_horizontal_pod_autoscaler_v2" "this" {
  count = local.create && var.enable_hpa && var.mode == "deployment" ? 1 : 0

  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.this[0].metadata[0].name
    labels    = local.tags
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "${helm_release.this[0].name}-opentelemetry-collector"
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_target_cpu_utilization
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_target_memory_utilization
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Pod Disruption Budget
# ---------------------------------------------------------------------------
resource "kubernetes_pod_disruption_budget_v1" "this" {
  count = local.create && var.enable_pdb ? 1 : 0

  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.this[0].metadata[0].name
    labels    = local.tags
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = helm_release.this[0].name
      }
    }

    max_unavailable = var.pdb_max_unavailable
  }
}

# ---------------------------------------------------------------------------
# Network Policy - restrict collector ingress to agent namespaces
# ---------------------------------------------------------------------------
resource "kubernetes_network_policy_v1" "this" {
  count = local.create && var.enable_network_policies ? 1 : 0

  metadata {
    name      = "${var.name}-ingress"
    namespace = kubernetes_namespace_v1.this[0].metadata[0].name
    labels    = local.tags
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = helm_release.this[0].name
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_expressions {
            key      = "kubernetes.io/metadata.name"
            operator = "In"
            values   = var.agent_namespaces
          }
        }
      }

      ports {
        port     = "4317"
        protocol = "TCP"
      }

      ports {
        port     = "4318"
        protocol = "TCP"
      }

      ports {
        port     = "8888"
        protocol = "TCP"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = var.namespace
          }
        }
      }
    }
  }
}

# CloudWatch Log Group for collector logs (if enabled)
resource "aws_cloudwatch_log_group" "this" {
  count = local.create && var.log_configuration.enabled ? 1 : 0

  name              = var.log_configuration.log_group_name
  retention_in_days = var.log_configuration.retention_days
  tags              = local.tags
}
