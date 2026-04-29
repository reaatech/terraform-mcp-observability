# Agent Skills: terraform-mcp-observability

This project uses AI agent skills to accelerate development. Each skill is a self-contained prompt + workflow that an AI agent can execute to produce specific deliverables.

## Available Skills

| Skill                | Description                                                                                          |
| -------------------- | ---------------------------------------------------------------------------------------------------- |
| `terraform-module`   | Generate a complete Terraform sub-module with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` |
| `terraform-root`     | Compose sub-modules into the root Terraform module                                                   |
| `dashboard-json`     | Generate a Grafana dashboard JSON from a specification                                               |
| `alert-rules`        | Generate PromQL alerting rules in YAML format                                                        |
| `otel-config`        | Generate OpenTelemetry Collector configuration YAML                                                  |
| `typescript-module`  | Generate a TypeScript utility module with types, validation, and tests                               |
| `prettier-eslint`    | Format and lint all code files                                                                       |
| `terraform-validate` | Run `terraform fmt -check` and `terraform validate` on all `.tf` files                               |
| `test-integration`   | Deploy to a local Kind cluster and validate end-to-end                                               |

## How to Invoke Skills

### Using the `/skill` command

```
/skill terraform-module --name otel-collector --description "OTel Collector deployment"
/skill terraform-root --name mcp-observability --description "Root module composing all sub-modules"
/skill dashboard-json --name overview --description "System health overview dashboard"
/skill alert-rules --category availability
/skill otel-config --pipeline traces --backend phoenix
/skill typescript-module --name otel-config-validator --description "Validates OTel collector YAML"
```

### Using GitHub Issues with Labels

Apply labels to issues to trigger skills automatically via CI:

| Label                    | Skill Triggered    |
| ------------------------ | ------------------ |
| `skill/terraform-module` | terraform-module   |
| `skill/terraform-root`   | terraform-root     |
| `skill/dashboard`        | dashboard-json     |
| `skill/alerts`           | alert-rules        |
| `skill/otel-config`      | otel-config        |
| `skill/typescript`       | typescript-module  |
| `skill/format`           | prettier-eslint    |
| `skill/validate`         | terraform-validate |
| `skill/integration-test` | test-integration   |

### Direct Agent Invocation

```bash
# Run a specific skill directly
pnpm skill:terraform-module --name grafana --description "Grafana deployment"
pnpm skill:terraform-root --name mcp-observability --description "Root module"
pnpm skill:dashboard-json --name llm-performance
pnpm skill:alert-rules --category cost
pnpm skill:otel-config --pipeline metrics
pnpm skill:typescript-module --name dashboard-provisioner
pnpm skill:format
pnpm skill:validate
pnpm skill:integration-test
```

## Skill: terraform-module

Generates a complete Terraform sub-module following terraform-aws-modules conventions.

**Inputs:**

- `--name` Module name (e.g., `otel-collector`)
- `--description` Module description
- `--provider` Provider (default: `aws`)
- `--resources` Comma-separated list of AWS resource types to include

**Outputs:**

- `src/modules/<name>/main.tf`
- `src/modules/<name>/variables.tf`
- `src/modules/<name>/outputs.tf`
- `src/modules/<name>/versions.tf`
- `src/modules/<name>/README.md`

**Example:**

```
/skill terraform-module --name prometheus --description "AWS Managed Prometheus workspace" --resources aws_prometheus_workspace,aws_prometheus_rule_group_namespace,aws_prometheus_alert_manager_definition
```

## Skill: terraform-root

Composes all sub-modules into a root Terraform module with sensible defaults.

**Inputs:**

- `--name` Root module name (default: `mcp-observability`)
- `--description` Module description
- `--submodules` Comma-separated list of sub-modules to include (e.g., `otel-collector,trace-backend,prometheus,grafana,alerting,logging`)

**Outputs:**

- `main.tf` — Module instantiations and data sources
- `variables.tf` — Root-level input variables
- `outputs.tf` — Endpoint URLs and references
- `versions.tf` — Provider constraints for the root module
- `README.md` — Quickstart and inputs/outputs tables

**Example:**

```
/skill terraform-root --name mcp-observability --description "Complete MCP observability stack" --submodules otel-collector,trace-backend,prometheus,grafana,alerting,logging
```

## Skill: dashboard-json

Generates a Grafana dashboard JSON file with pre-configured panels for GenAI observability.

**Inputs:**

- `--name` Dashboard name (e.g., `overview`)
- `--description` Dashboard description
- `--panels` Panel types to include (e.g., `latency,tokens,cost,errors`)

**Outputs:**

- `src/dashboards/<name>.json`

**Example:**

```
/skill dashboard-json --name llm-performance --description "Per-model LLM metrics" --panels latency-quantiles,token-usage,cost-by-model,error-rate
```

## Skill: alert-rules

Generates PromQL alerting rules in YAML format for AMP.

**Inputs:**

- `--category` Alert category: `availability`, `performance`, `llm`, `cost`, `resilience`

**Outputs:**

- `src/alert-rules/<category>.yaml`

**Example:**

```
/skill alert-rules --category cost
```

## Skill: otel-config

Generates OpenTelemetry Collector configuration YAML.

**Inputs:**

- `--pipeline` Pipeline type: `traces`, `metrics`, `logs`, `llm`
- `--backend` Target backend: `phoenix`, `langfuse`, `amp`, `xray`, `cloudwatch`

**Outputs:**

- `src/otel-config/<pipeline>-<backend>.yaml`

**Example:**

```
/skill otel-config --pipeline traces --backend langfuse
```

## Skill: typescript-module

Generates a TypeScript module with types, validation, and unit tests.

**Inputs:**

- `--name` Module name (kebab-case)
- `--description` Module description
- `--exports` Comma-separated list of exported functions/classes

**Outputs:**

- `src/lib/<name>/index.ts`
- `src/lib/<name>/types.ts`
- `src/lib/<name>/<name>.test.ts`

**Example:**

```
/skill typescript-module --name dashboard-provisioner --description "Provisions Grafana dashboards from JSON files" --exports provisionDashboards,validateDashboard
```

## Skill: prettier-eslint

Formats and lints all code files in the project.

**Inputs:** None

**Outputs:** Modified files in place

**Example:**

```
/skill format
```

## Skill: terraform-validate

Runs `terraform fmt -check` and `terraform validate` on all `.tf` files.

**Inputs:** None

**Outputs:** Validation report

**Example:**

```
/skill validate
```

## Skill: test-integration

Deploys the module to a local Kind cluster and validates end-to-end functionality.

**Inputs:**

- `--backend` Trace backend to test: `phoenix` or `langfuse`

**Outputs:** Test report with pass/fail status

**Example:**

```
/skill integration-test --backend phoenix
```

## Creating New Skills

To create a new skill:

1. Create directory: `skills/<skill-name>/`
2. Create `skills/<skill-name>/skills.md` with the skill definition
3. Add entry to `pnpm` scripts in `package.json`
4. Add label mapping for GitHub Actions CI trigger

**Path conventions:**

- Terraform modules go in `src/modules/<name>/`
- TypeScript utilities go in `src/lib/<name>/`
- Dashboards go in `src/dashboards/<name>.json`
- Alert rules go in `src/alert-rules/<category>.yaml`
- OTel configs go in `src/otel-config/<name>.yaml`

Skill definition template:

```markdown
# Skill: <skill-name>

## Description

<One sentence description>

## Inputs

| Input    | Type   | Required | Description |
| -------- | ------ | -------- | ----------- |
| `--name` | string | yes      | ...         |

## Outputs

- `path/to/output/file`

## Execution

<Step-by-step instructions for the agent>
```
