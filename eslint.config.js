import tseslint from "@typescript-eslint/eslint-plugin";
import tsesParser from "@typescript-eslint/parser";
import eslint from "@eslint/js";

export default [
  eslint.configs.recommended,
  {
    files: ["**/*.ts", "**/*.js"],
    languageOptions: {
      parser: tsesParser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
      },
      globals: {
        process: "readonly",
        console: "readonly",
        setTimeout: "readonly",
        clearTimeout: "readonly",
        setInterval: "readonly",
        clearInterval: "readonly",
        Buffer: "readonly",
        __dirname: "readonly",
        __filename: "readonly",
      },
    },
    plugins: {
      "@typescript-eslint": tseslint,
    },
    rules: {
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
      "no-console": "off",
    },
  },
  {
    ignores: ["node_modules/**", "dist/**", ".terraform/**", "pnpm-lock.yaml"],
  },
];
