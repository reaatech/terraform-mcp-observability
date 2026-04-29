/**
 * Types for OpenTelemetry Collector configuration generation.
 */

export interface MetricsEndpointConfig {
  amp?: {
    endpoint: string;
    region: string;
  };
  prometheus?: {
    endpoint: string;
  };
}

export interface TraceEndpointConfig {
  phoenix?: {
    endpoint: string;
  };
  langfuse?: {
    endpoint: string;
    apiKeyEnvVar?: string;
  };
  xray?: {
    region: string;
  };
}

export interface LogConfiguration {
  enabled: boolean;
  logGroupName: string;
  region: string;
  retentionDays: number;
}

export interface CollectorConfigOptions {
  environment: string;
  clusterName: string;
  enableMetrics: boolean;
  enableTraces: boolean;
  enableLogs: boolean;
  metricsEndpoints: MetricsEndpointConfig;
  traceEndpoints: TraceEndpointConfig;
  logConfiguration: LogConfiguration;
}

export interface GeneratedConfig {
  yaml: string;
  pipelines: string[];
  exporters: string[];
}
