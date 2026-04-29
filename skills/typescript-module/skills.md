# Skill: typescript-module

## Description

Generates a TypeScript utility module with types, validation, and unit tests.

## Inputs

| Input           | Type   | Required | Description                                        |
| --------------- | ------ | -------- | -------------------------------------------------- |
| `--name`        | string | yes      | Module name in kebab-case                          |
| `--description` | string | yes      | Module description                                 |
| `--exports`     | string | no       | Comma-separated list of exported functions/classes |

## Outputs

- `src/lib/<name>/index.ts` — Main module with exported functions
- `src/lib/<name>/types.ts` — TypeScript type definitions
- `src/lib/<name>/<name>.test.ts` — Vitest unit tests

## Execution

1. Parse CLI arguments for name, description, exports
2. Generate `types.ts` with interfaces relevant to the module domain:
   ```typescript
   export interface <Name>Options {
     // domain-specific options
   }
   ```
3. Generate `index.ts` with:
   - Proper imports from `./types`
   - Exported functions/classes with JSDoc comments
   - Input validation (throw on invalid inputs)
   - Example:

   ```typescript
   import type { <Name>Options } from "./types";

   /**
    * <description>
    */
   export function <exportName>(options: <Name>Options): string {
     if (!options) throw new Error("options is required");
     // implementation
     return "result";
   }
   ```

4. Generate `<name>.test.ts` with Vitest tests:

   ```typescript
   import { describe, it, expect } from "vitest";
   import { <exportName> } from "./index";

   describe("<name>", () => {
     it("returns expected result for valid input", () => {
       expect(<exportName>({ /* valid options */ })).toBe("result");
     });

     it("throws on invalid input", () => {
       expect(() => <exportName>(null as any)).toThrow("options is required");
     });
   });
   ```

5. All code uses strict TypeScript, ESLint-compliant, prettier-formatted

## Validation

After generation, run:

```bash
pnpm typecheck
pnpm test -- src/lib/<name>/<name>.test.ts
pnpm lint -- src/lib/<name>/
pnpm format -- src/lib/<name>/
```

## Notes

- Use `src/lib/<name>/` for all TypeScript modules to avoid collision with Terraform modules in `src/modules/`.
- Prefer pure functions over classes unless stateful behavior is required.
- Export types alongside functions so consumers can import both.
