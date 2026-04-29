# Skill: prettier-eslint

## Description

Formats and lints all code files in the project.

## Inputs

None

## Outputs

- Modified files in place (no new files created)

## Execution

1. Run `pnpm prettier --write .` to format all files:
   - Respects `.prettierignore` if present
   - Handles `.ts`, `.js`, `.json`, `.md`, `.yaml`, `.yml`, `.tf`
2. Run `pnpm eslint --fix .` to lint and auto-fix TypeScript/JavaScript:
   - Respects `.eslintignore` if present
   - Uses `@typescript-eslint/recommended` rules
3. Report summary:
   - Number of files formatted by Prettier
   - Number of files fixed by ESLint
   - Any remaining unfixable ESLint errors (print to stderr)

## Validation

After running, verify:

```bash
pnpm format:check   # should exit 0
pnpm lint           # should exit 0
```

## Notes

- If `pnpm format:check` or `pnpm lint` still fails after auto-fix, print the failing files and ask the user to resolve manually.
- Do not format files inside `.terraform/` or `node_modules/`.
