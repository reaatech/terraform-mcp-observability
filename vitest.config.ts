import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["src/**/*.test.ts", "tests/**/*.test.ts"],
    coverage: {
      include: ["src/lib/**/*.ts"],
      exclude: ["src/lib/**/types.ts"],
      thresholds: {
        statements: 85,
        branches: 85,
        functions: 85,
        lines: 85,
      },
      reporter: ["text", "text-summary"],
    },
  },
});
