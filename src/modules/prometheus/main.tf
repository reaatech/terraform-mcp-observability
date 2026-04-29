locals {
  create = var.create

  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "prometheus"
  }

  tags  = merge(local.default_tags, var.tags)
  alias = var.alias != "" ? var.alias : "${var.name}-${var.environment}"

  oidc_provider_id = var.create_irsa_role ? replace(var.oidc_provider_arn, "/^arn:aws:iam::\\d+:oidc-provider\\//", "") : ""
}

# ---------------------------------------------------------------------------
# AWS Managed Prometheus Workspace
# ---------------------------------------------------------------------------
resource "aws_prometheus_workspace" "this" {
  count = local.create ? 1 : 0

  alias = local.alias
  tags  = local.tags
}

# ---------------------------------------------------------------------------
# VPC Endpoint for AMP (optional)
# ---------------------------------------------------------------------------
resource "aws_vpc_endpoint" "amp" {
  count = local.create && var.create_vpc_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.aps-workspaces"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint_subnet_ids
  security_group_ids  = var.vpc_endpoint_security_group_ids
  private_dns_enabled = true

  tags = local.tags
}

# ---------------------------------------------------------------------------
# IAM Role for Remote Write (IRSA-compatible)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "irsa_assume" {
  count = local.create && var.create_irsa_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = var.irsa_service_account_subjects
    }
  }
}

data "aws_iam_policy_document" "remote_write" {
  count = local.create && var.create_irsa_role ? 1 : 0

  statement {
    actions   = ["aps:RemoteWrite"]
    resources = ["${aws_prometheus_workspace.this[0].arn}/*"]
  }
}

resource "aws_iam_role" "remote_write" {
  count = local.create && var.create_irsa_role ? 1 : 0

  name               = "${var.name}-remote-write-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy" "remote_write" {
  count = local.create && var.create_irsa_role ? 1 : 0

  name   = "${var.name}-remote-write-${var.environment}"
  role   = aws_iam_role.remote_write[0].id
  policy = data.aws_iam_policy_document.remote_write[0].json
}

# ---------------------------------------------------------------------------
# IAM Role for Query (Grafana IRSA)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "query" {
  count = local.create && var.create_irsa_role ? 1 : 0

  name               = "${var.name}-grafana-query-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "query" {
  count = local.create && var.create_irsa_role ? 1 : 0

  statement {
    actions   = ["aps:QueryMetrics", "aps:GetSeries", "aps:GetLabels", "aps:GetMetricMetadata"]
    resources = ["${aws_prometheus_workspace.this[0].arn}/*"]
  }
}

resource "aws_iam_role_policy" "query" {
  count = local.create && var.create_irsa_role ? 1 : 0

  name   = "${var.name}-query-${var.environment}"
  role   = aws_iam_role.query[0].id
  policy = data.aws_iam_policy_document.query[0].json
}

data "aws_region" "current" {}
