receivers:
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
      load: {}

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: ${memory_limiter_mib}
    spike_limit_mib: ${memory_spike_mib}
  batch:
    timeout: 1s
    send_batch_size: 1024
  resource:
    attributes:
      - key: environment
        value: ${environment}
        action: upsert
      - key: cluster
        value: ${cluster_name}
        action: upsert
      - key: mcp.system
        value: ${cluster_name}
        action: upsert

exporters:
%{ if enable_metrics && metrics_amp != null }
  prometheusremotewrite:
    endpoint: ${metrics_amp.endpoint}
    auth:
      authenticator: sigv4auth
%{ endif }
%{ if enable_metrics && metrics_prom != null }
  prometheusremotewrite/prometheus:
    endpoint: ${metrics_prom.endpoint}
%{ endif }
%{ if enable_traces && traces_xray != null }
  awsxray:
    region: ${traces_xray.region}
%{ endif }
%{ if enable_logs && logs_enabled }
  awscloudwatchlogs:
    log_group_name: ${logs_group}
    log_stream_name: otel-collector
    region: ${logs_region}
%{ endif }
%{ if enable_traces && traces_phoenix != null }
  otlphttp/phoenix:
    endpoint: ${traces_phoenix.endpoint}
%{ endif }
%{ if enable_traces && traces_langfuse != null }
  otlphttp/langfuse:
    endpoint: ${traces_langfuse.endpoint}
    headers:
      Authorization: Bearer $${LANGFUSE_API_KEY}
%{ endif }

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  pprof:
    endpoint: 0.0.0.0:1777
  prometheus:
    endpoint: 0.0.0.0:8888
%{ if enable_metrics && metrics_amp != null }
  sigv4auth:
    region: ${metrics_amp.region}
%{ endif }

service:
  extensions: [health_check, pprof, prometheus%{ if enable_metrics && metrics_amp != null }, sigv4auth%{ endif }]
  pipelines:
%{ if enable_traces && (traces_xray != null || traces_phoenix != null) }
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, resource]
      exporters:
%{ if traces_xray != null }        - awsxray%{ endif }
%{ if traces_phoenix != null }        - otlphttp/phoenix%{ endif }
%{ endif }
%{ if enable_traces && traces_langfuse != null }
    traces/llm:
      receivers: [otlp]
      processors: [memory_limiter, batch, resource]
      exporters: [otlphttp/langfuse]
%{ endif }
%{ if enable_metrics && (metrics_amp != null || metrics_prom != null) }
    metrics:
      receivers: [otlp, prometheus, hostmetrics]
      processors: [memory_limiter, batch, resource]
      exporters:
%{ if metrics_amp != null }        - prometheusremotewrite%{ endif }
%{ if metrics_prom != null }        - prometheusremotewrite/prometheus%{ endif }
%{ endif }
%{ if enable_logs && logs_enabled }
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [awscloudwatchlogs]
%{ endif }
