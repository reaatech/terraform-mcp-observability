# Skill: terraform-root

## Description

Composes all sub-modules into a root Terraform module with sensible defaults and unified inputs/outputs.

## Inputs

| Input           | Type   | Required | Description                                                                              |
| --------------- | ------ | -------- | ---------------------------------------------------------------------------------------- |
| `--name`        | string | yes      | Root module name (default: `mcp-observability`)                                          |
| `--description` | string | yes      | Module description                                                                       |
| `--submodules`  | string | no       | Comma-separated list: `otel-collector,trace-backend,prometheus,grafana,alerting,logging` |

## Outputs

- `main.tf` — Module instantiations, data sources, and wiring
- `variables.tf` — Root-level input variables
- `outputs.tf` — Endpoint URLs, ARNs, and references
- `versions.tf` — Provider constraints
- `README.md` — Quickstart, inputs/outputs tables

## Execution

1. Parse `--name`, `--description`, and `--submodules`
2. Generate `versions.tf` requiring Terraform >= 1.5.7 and all providers (aws, helm, kubernetes)
3. Generate `variables.tf` with:
   - `cluster_name`, `environment`, `trace_backend` (`phoenix` | `langfuse` | `none`)
   - `enable_alerting`, `enable_logging`
   - `tags` (map)
4. Generate `main.tf` with module blocks:
   ```hcl
   module "otel_collector" {
     source = "./src/modules/otel-collector"
     create = true
     tags   = var.tags
     # ... pass through other variables
   }
   ```
5. Generate `outputs.tf` aggregating sub-module outputs:
   ```hcl
   output "trace_backend_url" {
     description = "URL of the trace backend UI"
     value       = module.trace_backend.endpoint_url
   }
   ```
6. Generate `README.md` with quickstart HCL snippet and full inputs/outputs tables
7. Run `terraform fmt` on generated files

## Validation

After generation, run:

```bash
terraform init -backend=false && terraform validate
```

## Notes

- The root module should not contain resource definitions directly — only module calls, data sources, and locals.
- Use `count = var.trace_backend == "phoenix" ? 1 : 0` patterns inside the `trace-backend` sub-module, not at the root level, to keep root code declarative.
