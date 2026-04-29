locals {
  create      = var.create && var.trace_backend != "none"
  is_phoenix  = var.trace_backend == "phoenix"
  is_langfuse = var.trace_backend == "langfuse"

  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "trace-backend"
    Backend     = var.trace_backend
  }

  tags = merge(local.default_tags, var.tags)
}

# ---------------------------------------------------------------------------
# Kubernetes Namespace
# ---------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "this" {
  count = local.create ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# ---------------------------------------------------------------------------
# Secure secrets: database password + Langfuse salt
#
# Rotation: To rotate credentials, taint the random_password resource:
#   terraform taint module.trace_backend.random_password.db[0]
#   terraform taint module.trace_backend.random_password.salt[0]
# Then run terraform apply. This regenerates the password/salt and updates
# the corresponding Secrets Manager entry and Helm release values.
# ---------------------------------------------------------------------------
resource "random_password" "db" {
  count = local.create && var.create_database ? 1 : 0

  length  = 32
  special = false

  keepers = {
    name = var.name
  }
}

resource "random_password" "salt" {
  count = local.create && local.is_langfuse ? 1 : 0

  length  = 32
  special = true

  keepers = {
    name = var.name
  }
}

resource "aws_secretsmanager_secret" "db" {
  count = local.create && var.create_database ? 1 : 0

  name = "${var.name}-db-password-${var.environment}"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  count = local.create && var.create_database ? 1 : 0

  secret_id     = aws_secretsmanager_secret.db[0].id
  secret_string = random_password.db[0].result
}

# ---------------------------------------------------------------------------
# RDS PostgreSQL for Phoenix
# ---------------------------------------------------------------------------
resource "aws_db_instance" "postgres" {
  count = local.create && local.is_phoenix && var.create_database ? 1 : 0

  identifier     = "${var.name}-postgres-${var.environment}"
  engine         = "postgres"
  engine_version = var.db_postgres_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = var.db_storage_encrypted

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db[0].result
  port     = var.db_port

  vpc_security_group_ids = var.db_vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name

  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot     = var.environment != "prod"
  deletion_protection     = var.environment == "prod"

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Phoenix Deployment
# ---------------------------------------------------------------------------
resource "helm_release" "phoenix" {
  count = local.create && local.is_phoenix ? 1 : 0

  name       = "${var.name}-phoenix"
  namespace  = var.namespace
  repository = "https://arize-ai.github.io/phoenix-helm-charts"
  chart      = "phoenix"
  version    = var.phoenix_helm_chart_version

  depends_on = [kubernetes_namespace_v1.this]

  set = concat(
    [
      {
        name  = "replicaCount"
        value = var.phoenix_replicas
      },
      {
        name  = "service.type"
        value = "ClusterIP"
      },
    ],
    var.create_database ? [
      {
        name  = "db.url"
        value = "postgresql://${var.db_username}:${random_password.db[0].result}@${aws_db_instance.postgres[0].endpoint}/${var.db_name}"
      }
    ] : []
  )
}

# ---------------------------------------------------------------------------
# ElastiCache Redis for Langfuse
# ---------------------------------------------------------------------------
resource "aws_elasticache_cluster" "redis" {
  count = local.create && local.is_langfuse && var.create_redis ? 1 : 0

  cluster_id           = "${var.name}-redis-${var.environment}"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_nodes
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379

  subnet_group_name  = var.redis_subnet_group_name
  security_group_ids = var.redis_security_group_ids

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Langfuse Deployment
# ---------------------------------------------------------------------------
resource "helm_release" "langfuse" {
  count = local.create && local.is_langfuse ? 1 : 0

  name       = "${var.name}-langfuse"
  namespace  = var.namespace
  repository = "https://langfuse.github.io/langfuse-k8s"
  chart      = "langfuse"
  version    = var.langfuse_helm_chart_version

  depends_on = [kubernetes_namespace_v1.this]

  set = concat(
    [
      {
        name  = "langfuse.web.replicas"
        value = var.langfuse_web_replicas
      },
      {
        name  = "langfuse.salt"
        value = random_password.salt[0].result
      },
      {
        name  = "service.type"
        value = "ClusterIP"
      },
    ],
    var.create_database ? [
      {
        name  = "postgresql.auth.password"
        value = random_password.db[0].result
      }
    ] : [],
    var.create_redis ? [
      {
        name  = "redis.host"
        value = aws_elasticache_cluster.redis[0].cache_nodes[0].address
      }
    ] : []
  )
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
      "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
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
              name = local.is_phoenix ? kubernetes_service_v1.phoenix[0].metadata[0].name : kubernetes_service_v1.langfuse[0].metadata[0].name
              port {
                number = local.is_phoenix ? 6006 : 3000
              }
            }
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Kubernetes Services
# ---------------------------------------------------------------------------
resource "kubernetes_service_v1" "phoenix" {
  count = local.create && local.is_phoenix ? 1 : 0

  metadata {
    name      = "${var.name}-phoenix"
    namespace = var.namespace
    labels    = local.tags
  }

  depends_on = [kubernetes_namespace_v1.this]

  spec {
    selector = {
      "app.kubernetes.io/name"     = "phoenix"
      "app.kubernetes.io/instance" = helm_release.phoenix[0].name
    }

    port {
      name        = "http"
      port        = 6006
      target_port = 6006
      protocol    = "TCP"
    }

    port {
      name        = "otlp-grpc"
      port        = 4317
      target_port = 4317
      protocol    = "TCP"
    }

    port {
      name        = "otlp-http"
      port        = 4318
      target_port = 4318
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service_v1" "langfuse" {
  count = local.create && local.is_langfuse ? 1 : 0

  metadata {
    name      = "${var.name}-langfuse"
    namespace = var.namespace
    labels    = local.tags
  }

  depends_on = [kubernetes_namespace_v1.this]

  spec {
    selector = {
      "app.kubernetes.io/name"     = "langfuse"
      "app.kubernetes.io/instance" = helm_release.langfuse[0].name
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
