# Skill: terraform-validate

## Description

Runs `terraform fmt -check` and `terraform validate` on all `.tf` files in the project.

## Inputs

None

## Outputs

- Validation report (stdout)
- Non-zero exit code on failure

## Execution

1. Run `terraform fmt -check -recursive` from the repository root to verify formatting
2. Discover all Terraform module directories:
   - `src/modules/*/` (top-level modules)
   - `src/modules/*/*/` (nested modules, e.g., `trace-backend` children if any)
   - `examples/*/` (example configurations)
3. For each discovered directory containing `.tf` files:
   - Run `terraform init -backend=false` (silent, suppress logs)
   - Run `terraform validate` (print output)
4. Print a pass/fail summary table:
   ```
   Module                  Validate   Fmt
   ---------------------- ---------- -----
   src/modules/otel-collector   PASS   PASS
   examples/complete            PASS   PASS
   ```

## Validation

A successful run exits with code 0 and prints:

```
All Terraform validations passed.
```

## Notes

- Directories without `.tf` files are skipped silently.
- If `terraform` is not installed, print a clear error message and exit non-zero.
- The `validate` pnpm script wraps this skill: `pnpm validate`.
