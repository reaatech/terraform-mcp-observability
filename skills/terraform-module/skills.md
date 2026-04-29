# Skill: terraform-module

## Description

Generates a complete Terraform sub-module following terraform-aws-modules conventions.

## Inputs

| Input           | Type                                      | Required | Description                                           |
| --------------- | ----------------------------------------- | -------- | ----------------------------------------------------- |
| `--name`        | string                                    | yes      | Module name in kebab-case (e.g., `otel-collector`)    |
| `--description` | Module description for README and outputs |
| `--provider`    | string                                    | no       | Provider to use (default: `aws`)                      |
| `--resources`   | string                                    | no       | Comma-separated list of AWS resource types to include |

## Outputs

- `src/modules/<name>/main.tf` — Resource definitions
- `src/modules/<name>/variables.tf` — Input variables with `create` flag pattern
- `src/modules/<name>/outputs.tf` — Standardized outputs (arn, id, etc.)
- `src/modules/<name>/versions.tf` — Provider version constraints
- `src/modules/<name>/README.md` — Auto-generated module documentation

## Execution

1. Parse CLI arguments for name, description, provider, resources
2. Generate `versions.tf` with Terraform >= 1.5.7 and provider version constraints:
   ```hcl
   terraform {
     required_version = ">= 1.5.7"
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = ">= 6.28"
       }
     }
   }
   ```
3. Generate `variables.tf` with:
   - `variable "create" { type = bool; default = true }`
   - `variable "tags" { type = map(string); default = {} }`
   - Resource-specific variables derived from `--resources`
4. Generate `main.tf` with conditional resource creation:
   ```hcl
   resource "aws_xxx" "this" {
     count = var.create ? 1 : 0
     # ... resource attributes
     tags = var.tags
   }
   ```
5. Generate `outputs.tf` with standard outputs:
   ```hcl
   output "arn" {
     value       = var.create ? aws_xxx.this[0].arn : null
     description = "ARN of the created resource"
   }
   ```
6. Generate `README.md` with:
   - Module description
   - Requirements table
   - Inputs table (auto-generated from variables.tf)
   - Outputs table (auto-generated from outputs.tf)
7. Run `terraform fmt` on generated files

## Validation

After generation, run:

```bash
cd src/modules/<name> && terraform init -backend=false && terraform validate
```

## Notes

- Nested sub-modules (e.g., `trace-backend/phoenix`) are created by running this skill for the parent and then manually adding child directories. Use the `terraform-root` skill for root-level composition.
- Always include `create` and `tags` variables to follow project conventions.
