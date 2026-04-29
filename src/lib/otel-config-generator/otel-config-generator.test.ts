import { describe, it, expect } from "vitest";
import { generateCollectorConfig, validateOptions } from "./index";
import type { CollectorConfigOptions } from "./types";

const baseOptions: CollectorConfigOptions = {
  environment: "prod",
  clusterName: "production",
  enableMetrics: true,
  enableTraces: true,
  enableLogs: true,
  metricsEndpoints: {
    amp: {
      endpoint:
        "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-xxx/api/v1/remote_write",
      region: "us-east-1",
    },
  },
  traceEndpoints: {
    phoenix: { endpoint: "http://phoenix.observability:6006/v1/traces" },
  },
  logConfiguration: {
    enabled: true,
    logGroupName: "/mcp/observability/collector",
    region: "us-east-1",
    retentionDays: 7,
  },
};

describe("validateOptions", () => {
  it("passes for valid options", () => {
    expect(() => validateOptions(baseOptions)).not.toThrow();
  });

  it("throws when environment is missing", () => {
    expect(() => validateOptions({ ...baseOptions, environment: "" })).toThrow(
      "environment is required",
    );
  });

  it("throws when metrics enabled but no endpoints configured", () => {
    expect(() => validateOptions({ ...baseOptions, metricsEndpoints: {} })).toThrow(
      "At least one metrics endpoint must be configured",
    );
  });

  it("throws when traces enabled but no endpoints configured", () => {
    expect(() => validateOptions({ ...baseOptions, traceEndpoints: {} })).toThrow(
      "At least one trace endpoint must be configured",
    );
  });

  it("throws when logs enabled but log config is disabled", () => {
    expect(() =>
      validateOptions({
        ...baseOptions,
        logConfiguration: { ...baseOptions.logConfiguration, enabled: false },
      }),
    ).toThrow("logConfiguration.enabled must be true");
  });
});

describe("generateCollectorConfig", () => {
  it("generates a valid YAML config with all pipelines", () => {
    const result = generateCollectorConfig(baseOptions);

    expect(result.yaml).toContain("receivers:");
    expect(result.yaml).toContain("processors:");
    expect(result.yaml).toContain("exporters:");
    expect(result.yaml).toContain("extensions:");
    expect(result.yaml).toContain("service:");

    expect(result.pipelines).toContain("traces");
    expect(result.pipelines).toContain("metrics");
    expect(result.pipelines).toContain("logs");

    expect(result.exporters).toContain("prometheusremotewrite");
    expect(result.exporters).toContain("otlphttp/phoenix");
    expect(result.exporters).toContain("awscloudwatchlogs");
  });

  it("includes environment and cluster in resource processor", () => {
    const result = generateCollectorConfig(baseOptions);
    expect(result.yaml).toContain("value: prod");
    expect(result.yaml).toContain("value: production");
  });

  it("generates traces/llm pipeline when langfuse is configured", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      traceEndpoints: {
        langfuse: {
          endpoint: "http://langfuse.observability:8080",
          apiKeyEnvVar: "LF_API_KEY",
        },
      },
    };
    const result = generateCollectorConfig(options);

    expect(result.pipelines).toContain("traces/llm");
    expect(result.yaml).toContain("traces/llm:");
    expect(result.yaml).toContain("exporters: [otlphttp/langfuse]");
    expect(result.yaml).toContain("Authorization: Bearer ${LF_API_KEY}");
  });

  it("uses default LANGFUSE_API_KEY env var when apiKeyEnvVar is not set", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      traceEndpoints: {
        langfuse: { endpoint: "http://langfuse.observability:8080" },
      },
    };
    const result = generateCollectorConfig(options);
    expect(result.yaml).toContain("Authorization: Bearer ${LANGFUSE_API_KEY}");
  });

  it("omits logs pipeline when enableLogs is false", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      enableLogs: false,
      logConfiguration: { ...baseOptions.logConfiguration, enabled: false },
    };
    const result = generateCollectorConfig(options);
    expect(result.pipelines).not.toContain("logs");
    expect(result.yaml).not.toContain("awscloudwatchlogs");
  });

  it("omits metrics pipeline when enableMetrics is false", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      enableMetrics: false,
      metricsEndpoints: {},
    };
    const result = generateCollectorConfig(options);
    expect(result.pipelines).not.toContain("metrics");
    expect(result.yaml).not.toContain("prometheusremotewrite");
  });

  it("generates prometheus (non-AMP) remote write exporter", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      metricsEndpoints: {
        prometheus: {
          endpoint: "http://prometheus.monitoring:9090/api/v1/write",
        },
      },
    };
    const result = generateCollectorConfig(options);
    expect(result.exporters).toContain("prometheusremotewrite/prometheus");
    expect(result.yaml).toContain("prometheusremotewrite/prometheus:");
    expect(result.yaml).toContain("http://prometheus.monitoring:9090/api/v1/write");
  });

  it("includes xray exporter when configured", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      traceEndpoints: {
        xray: { region: "us-east-1" },
      },
    };
    const result = generateCollectorConfig(options);
    expect(result.exporters).toContain("awsxray");
    expect(result.yaml).toContain("awsxray:");
  });

  it("includes sigv4auth extension when AMP is configured", () => {
    const result = generateCollectorConfig(baseOptions);
    expect(result.yaml).toContain("sigv4auth:");
    expect(result.yaml).toContain("region: us-east-1");
    expect(result.yaml).toContain("service: aps");
    expect(result.yaml).toContain("extensions: [health_check, pprof, prometheus, sigv4auth]");
  });

  it("omits sigv4auth when AMP is not configured", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      metricsEndpoints: {
        prometheus: {
          endpoint: "http://prometheus.monitoring:9090/api/v1/write",
        },
      },
    };
    const result = generateCollectorConfig(options);
    expect(result.yaml).not.toContain("sigv4auth");
    expect(result.yaml).toContain("extensions: [health_check, pprof, prometheus]");
  });

  it("omits sigv4auth when metrics are disabled", () => {
    const options: CollectorConfigOptions = {
      ...baseOptions,
      enableMetrics: false,
      metricsEndpoints: {},
    };
    const result = generateCollectorConfig(options);
    expect(result.yaml).not.toContain("sigv4auth");
  });
});
