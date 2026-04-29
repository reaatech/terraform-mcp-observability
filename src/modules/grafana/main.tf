locals {
  create = var.create

  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "grafana"
  }

  tags = merge(local.default_tags, var.tags)

  dashboards = {
    for f in var.dashboard_files : basename(f) => file(f)
  }
}

# ---------------------------------------------------------------------------
# Grafana Admin Password from Secrets Manager
# ---------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "admin" {
  count = var.admin_password_secret_name != "" ? 1 : 0

  secret_id = var.admin_password_secret_name
}

locals {
  admin_password = var.admin_password_secret_name != "" ? data.aws_secretsmanager_secret_version.admin[0].secret_string : ""
  sigv4_region   = var.amp_region != "" ? var.amp_region : (var.region != "" ? var.region : data.aws_region.current.id)
}

check "admin_password_warning" {
  assert {
    condition     = var.admin_password_secret_name != ""
    error_message = "admin_password_secret_name must be set to an AWS Secrets Manager secret in all environments. The chart default password 'admin' is not safe."
  }
}

# ---------------------------------------------------------------------------
# Grafana Helm Release
# ---------------------------------------------------------------------------
resource "helm_release" "this" {
  count = local.create ? 1 : 0

  name       = var.name
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.helm_chart_version

  set = concat(
    [
      {
        name  = "replicas"
        value = var.replica_count
      },
      {
        name  = "service.type"
        value = "ClusterIP"
      },
    ],
    local.admin_password != "" ? [
      {
        name  = "adminPassword"
        value = local.admin_password
      }
    ] : []
  )

  values = [
    yamlencode({
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "AMP"
              type      = "prometheus"
              access    = "proxy"
              url       = var.amp_workspace_endpoint
              isDefault = true
              uid       = "prometheus"
              jsonData = {
                httpMethod    = "POST"
                sigV4Auth     = true
                sigV4AuthType = "default"
                sigV4Region   = local.sigv4_region
              }
            }
          ]
        }
      }
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [
            {
              name            = "mcp"
              orgId           = 1
              folder          = "MCP Observability"
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/mcp"
              }
            }
          ]
        }
      }
      dashboards = {
        mcp = {
          for filename, content in local.dashboards : replace(filename, ".json", "") => {
            json = content
          }
        }
      }
      serviceAccount = var.create_irsa_role ? {
        annotations = {
          "eks.amazonaws.com/role-arn" = var.irsa_role_arn
        }
      } : {}
    })
  ]
}

# ---------------------------------------------------------------------------
# Kubernetes Ingress
# ---------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "this" {
  count = local.create && var.enable_ingress ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.tags

    annotations = {
      "kubernetes.io/ingress.class"                 = var.ingress_class
      "cert-manager.io/cluster-issuer"              = var.ingress_cert_issuer
      "nginx.ingress.kubernetes.io/ssl-redirect"    = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "20m"
    }
  }

  spec {
    dynamic "tls" {
      for_each = var.ingress_tls_enabled ? toset([1]) : toset([])
      content {
        hosts       = [var.ingress_host]
        secret_name = "${var.name}-tls"
      }
    }

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "${helm_release.this[0].name}-grafana"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}

data "aws_region" "current" {}
