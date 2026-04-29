# Changelog

## [1.0.0] - 2026-04-28

### Added

- Drop-in Terraform module for complete MCP observability stack
- OpenTelemetry Collector deployment with Helm (deployment/daemonset/statefulset)
- Arize Phoenix and Langfuse trace backend support
- AWS Managed Prometheus workspace with IRSA for remote write
- Grafana deployment with pre-built GenAI observability dashboards
- PromQL alerting rules for availability, performance, LLM, cost, and resilience
- CloudWatch Logs aggregation with structured OTel forwarding
- SNS-based alert notifications with PagerDuty and Slack integration
- TypeScript validation library for alert rules, dashboards, and OTel configs
- AI agent skill definitions for automated module generation
- CI/CD pipeline with PR checks and automated releases
