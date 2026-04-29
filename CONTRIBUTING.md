# Contributing to terraform-mcp-observability

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) >= 21
- [pnpm](https://pnpm.io/) >= 9
- [Terraform](https://www.terraform.io/) >= 1.5.7
- [Docker](https://www.docker.com/) (for local testing)
- [Kind](https://kind.sigs.k8s.io/) (for integration testing)

### Setup

```bash
# Clone the repository
git clone https://github.com/reaatech/terraform-mcp-observability.git
cd terraform-mcp-observability

# Install dependencies
pnpm install

# Verify setup
pnpm build
pnpm test
pnpm lint
```

## Development Workflow

### Project Structure

```
terraform-mcp-observability/
├── src/
│   ├── modules/          # Terraform sub-modules
│   ├── lib/              # TypeScript utilities, validators, generators
│   ├── dashboards/       # Grafana dashboard JSON files
│   ├── alert-rules/      # PromQL alerting rules (YAML)
│   ├── otel-config/      # OTel Collector configs (YAML)
├── examples/             # Usage examples
├── tests/                # Unit and integration tests
├── skills/               # AI agent skill definitions
└── scripts/              # Utility scripts
```

### Making Changes

1. **Create a branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow existing code style and conventions
   - Add tests for new functionality
   - Update documentation as needed

3. **Run pre-commit checks**

   ```bash
   pnpm format    # Run prettier
   pnpm lint      # Run ESLint
   pnpm typecheck # Run TypeScript compiler
   pnpm test      # Run unit tests
   pnpm validate  # Run terraform fmt/validate
   ```

4. **Commit your changes**

   This project follows [Conventional Commits](https://www.conventionalcommits.org/).

   ```bash
   git commit -m "feat: add new dashboard for LLM performance"
   git commit -m "fix: correct PromQL query for error rate"
   git commit -m "docs: update README with new examples"
   ```

5. **Push and open a Pull Request**

   ```bash
   git push origin feature/your-feature-name
   ```

## Using Agent Skills

This project supports AI agent skills for accelerated development. See [AGENTS.md](./AGENTS.md) for details.

```bash
# Generate a new Terraform module
/skill terraform-module --name grafana --description "Grafana deployment"

# Generate a dashboard
/skill dashboard-json --name llm-performance --panels latency-quantiles,token-usage,cost-by-model

# Generate alert rules
/skill alert-rules --category cost

# Format and lint
/skill format

# Validate Terraform
/skill validate
```

## Testing

### Unit Tests

```bash
pnpm test
```

### Integration Tests

Requires Docker and Kind:

```bash
# Test with Phoenix backend
/skill integration-test --backend phoenix

# Test with Langfuse backend
/skill integration-test --backend langfuse
```

### Manual Terraform Validation

```bash
# Format check
terraform fmt -check -recursive

# Validate all modules
cd src/modules/otel-collector && terraform init -backend=false && terraform validate
cd ../prometheus && terraform init -backend=false && terraform validate
cd ../grafana && terraform init -backend=false && terraform validate
```

## Code Conventions

### TypeScript

- Strict mode enabled
- Use `const` over `let` where possible
- Prefer functional style over classes
- Export types alongside functions
- Use template literals over string concatenation

### Terraform

- Follow [terraform-aws-modules](https://github.com/terraform-aws-modules) conventions
- Always include `create` flag pattern for conditional creation
- Pin provider versions in `versions.tf`
- Include `tags` variable and propagate to all resources
- Use `count` for conditional resources, not `count = var.create ? 1 : 0` patterns within resources

### YAML (OTel configs, alert rules)

- Use environment variable substitution for secrets
- Include comments for complex PromQL queries
- Follow OpenTelemetry Collector configuration schema

### Grafana Dashboards

- Use AMP data source UID `prometheus`
- Include template variables: `cluster`, `namespace`, `environment`, `model`
- Use consistent color schemes
- Set appropriate time ranges and refresh intervals

## Documentation

- Update README.md for user-facing changes
- Add inline JSDoc comments for exported TypeScript functions
- Update ARCHITECTURE.md for significant architectural changes
- Update DEV_PLAN.md to reflect completed/pending work

## Release Process

Releases are automated via GitHub Actions when a version tag is pushed:

```bash
# Create a release (maintainers only)
git tag v1.0.0
git push origin v1.0.0
```

This triggers the release workflow which:

1. Runs all tests
2. Generates changelog
3. Creates a GitHub release

## Code of Conduct

Be respectful and inclusive. We are committed to providing a welcoming and harassment-free experience for everyone.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
