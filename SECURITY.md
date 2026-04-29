# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please do **not** open a public issue. Instead, report it via email to [security@reaatech.com](mailto:security@reaatech.com). You may also use GitHub's [private vulnerability reporting](https://github.com/reaatech/terraform-mcp-observability/security/advisories/new) feature if enabled on the repository.

We will acknowledge receipt of your report within 48 hours and provide a timeline for resolution within 5 business days. We follow a coordinated disclosure process: the fix will be released first, and the vulnerability will be disclosed publicly after users have had a reasonable window to upgrade.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Security Best Practices for Users

- Never commit `.tfstate` files or `.env` files to version control
- Use AWS Secrets Manager for credentials (PagerDuty routing keys, Slack webhooks, database passwords, Grafana admin password) rather than plaintext variables
- Enable `deletion_protection` on RDS instances in production
- Rotate database passwords regularly via Terraform lifecycle management
- Use IRSA (IAM Roles for Service Accounts) instead of long-lived AWS credentials
- Review and customize the alert rule pricing thresholds in `src/alert-rules/cost.yaml` for your model costs
- Pin Helm chart versions in production to avoid unexpected breaking changes
