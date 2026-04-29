import type {
  CollectorConfigOptions,
  GeneratedConfig,
  MetricsEndpointConfig,
  TraceEndpointConfig,
} from "./types";

/**
 * Validates collector configuration options.
 * Throws if required fields are missing or invalid.
 */
export function validateOptions(options: CollectorConfigOptions): void {
  if (!options.environment) {
    throw new Error("environment is required");
  }
  if (options.enableMetrics && !hasAnyMetricExporter(options.metricsEndpoints)) {
    throw new Error("At least one metrics endpoint must be configured when enableMetrics is true");
  }
  if (options.enableTraces && !hasAnyTraceExporter(options.traceEndpoints)) {
    throw new Error("At least one trace endpoint must be configured when enableTraces is true");
  }
  if (options.enableLogs && !options.logConfiguration.enabled) {
    throw new Error("logConfiguration.enabled must be true when enableLogs is true");
  }
}

function hasAnyMetricExporter(endpoints: MetricsEndpointConfig): boolean {
  return Boolean(endpoints.amp || endpoints.prometheus);
}

function hasAnyTraceExporter(endpoints: TraceEndpointConfig): boolean {
  return Boolean(endpoints.phoenix || endpoints.langfuse || endpoints.xray);
}

/**
 * Generates an OpenTelemetry Collector configuration YAML string.
 */
export function generateCollectorConfig(options: CollectorConfigOptions): GeneratedConfig {
  validateOptions(options);

  const pipelines: string[] = [];
  const exporters: string[] = [];

  const receivers = generateReceivers();
  const processors = generateProcessors(options);
  const exportersYaml = generateExporters(options, exporters);
  const extensions = generateExtensions(options);
  const serviceYaml = generateService(options, pipelines);

  const yaml = `${receivers}\n${processors}\n${exportersYaml}\n${extensions}\n${serviceYaml}`;

  return { yaml, pipelines, exporters };
}

function generateReceivers(): string {
  return `receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  prometheus:
    config:
      scrape_configs:
        - job_name: otel-collector
          static_configs:
            - targets: [localhost:8888]
  hostmetrics:
    collection_interval: 30s
    scrapers:
      cpu: {}
      memory: {}
      disk: {}
      load: {}`;
}

function generateProcessors(options: CollectorConfigOptions): string {
  return `processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128
  batch:
    timeout: 1s
    send_batch_size: 1024
  resource:
    attributes:
      - key: environment
        value: ${options.environment}
        action: upsert
      - key: cluster
        value: ${options.clusterName}
        action: upsert`;
}

function generateExporters(options: CollectorConfigOptions, exporterList: string[]): string {
  const lines: string[] = ["exporters:"];

  if (options.enableMetrics && options.metricsEndpoints.amp) {
    lines.push(`  prometheusremotewrite:`);
    lines.push(`    endpoint: ${options.metricsEndpoints.amp.endpoint}`);
    lines.push(`    auth:`);
    lines.push(`      authenticator: sigv4auth`);
    exporterList.push("prometheusremotewrite");
  }

  if (options.enableMetrics && options.metricsEndpoints.prometheus) {
    lines.push(`  prometheusremotewrite/prometheus:`);
    lines.push(`    endpoint: ${options.metricsEndpoints.prometheus.endpoint}`);
    exporterList.push("prometheusremotewrite/prometheus");
  }

  if (options.enableTraces && options.traceEndpoints.xray) {
    lines.push(`  awsxray:`);
    lines.push(`    region: ${options.traceEndpoints.xray.region}`);
    exporterList.push("awsxray");
  }

  if (options.enableLogs && options.logConfiguration.enabled) {
    lines.push(`  awscloudwatchlogs:`);
    lines.push(`    log_group_name: ${options.logConfiguration.logGroupName}`);
    lines.push(`    log_stream_name: otel-collector`);
    lines.push(`    region: ${options.logConfiguration.region}`);
    exporterList.push("awscloudwatchlogs");
  }

  if (options.enableTraces && options.traceEndpoints.phoenix) {
    lines.push(`  otlphttp/phoenix:`);
    lines.push(`    endpoint: ${options.traceEndpoints.phoenix.endpoint}`);
    exporterList.push("otlphttp/phoenix");
  }

  if (options.enableTraces && options.traceEndpoints.langfuse) {
    const apiKeyRef = options.traceEndpoints.langfuse.apiKeyEnvVar ?? "LANGFUSE_API_KEY";
    lines.push(`  otlphttp/langfuse:`);
    lines.push(`    endpoint: ${options.traceEndpoints.langfuse.endpoint}`);
    lines.push(`    headers:`);
    lines.push(`      Authorization: Bearer \${${apiKeyRef}}`);
    exporterList.push("otlphttp/langfuse");
  }

  return lines.join("\n");
}

function generateExtensions(options: CollectorConfigOptions): string {
  const hasAmp = options.enableMetrics && Boolean(options.metricsEndpoints.amp);
  const lines = [
    "extensions:",
    "  health_check:",
    "    endpoint: 0.0.0.0:13133",
    "  pprof:",
    "    endpoint: 0.0.0.0:1777",
    "  prometheus:",
    "    endpoint: 0.0.0.0:8888",
  ];
  if (hasAmp) {
    lines.push("  sigv4auth:");
    lines.push(`    region: ${options.metricsEndpoints.amp!.region}`);
    lines.push("    service: aps");
  }
  return lines.join("\n");
}

function generateService(options: CollectorConfigOptions, pipelineList: string[]): string {
  const hasAmp = options.enableMetrics && Boolean(options.metricsEndpoints.amp);
  const extensionList = ["health_check", "pprof", "prometheus"];
  if (hasAmp) extensionList.push("sigv4auth");

  const lines: string[] = [
    "service:",
    `  extensions: [${extensionList.join(", ")}]`,
    "  pipelines:",
  ];

  if (options.enableTraces) {
    lines.push("    traces:");
    lines.push("      receivers: [otlp]");
    lines.push("      processors: [memory_limiter, batch, resource]");
    lines.push("      exporters:");
    if (options.traceEndpoints.xray) lines.push("        - awsxray");
    if (options.traceEndpoints.phoenix) lines.push("        - otlphttp/phoenix");
    pipelineList.push("traces");
  }

  if (options.enableTraces && options.traceEndpoints.langfuse) {
    lines.push("    traces/llm:");
    lines.push("      receivers: [otlp]");
    lines.push("      processors: [memory_limiter, batch, resource]");
    lines.push("      exporters: [otlphttp/langfuse]");
    pipelineList.push("traces/llm");
  }

  if (options.enableMetrics) {
    lines.push("    metrics:");
    lines.push("      receivers: [otlp, prometheus, hostmetrics]");
    lines.push("      processors: [memory_limiter, batch, resource]");
    lines.push("      exporters:");
    if (options.metricsEndpoints.amp) lines.push("        - prometheusremotewrite");
    if (options.metricsEndpoints.prometheus)
      lines.push("        - prometheusremotewrite/prometheus");
    pipelineList.push("metrics");
  }

  if (options.enableLogs && options.logConfiguration.enabled) {
    lines.push("    logs:");
    lines.push("      receivers: [otlp]");
    lines.push("      processors: [memory_limiter, batch]");
    lines.push("      exporters: [awscloudwatchlogs]");
    pipelineList.push("logs");
  }

  return lines.join("\n");
}
