locals {
  create = var.create

  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "logging"
  }

  tags = merge(local.default_tags, var.tags)
}

# ---------------------------------------------------------------------------
# CloudWatch Log Groups
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  for_each = local.create ? var.log_groups : {}

  name              = each.key
  retention_in_days = each.value.retention_days
  kms_key_id        = each.value.kms_key_id
  tags              = local.tags
}
