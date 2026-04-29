alertmanager_config: |
  route:
    receiver: default
    group_by: ['alertname', 'severity']
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 4h
    routes:
      - match:
          severity: critical
        receiver: pagerduty
        continue: true
      - match:
          severity: critical
        receiver: sns-critical
      - match:
          severity: high
        receiver: sns-high
      - match:
          severity: warning
        receiver: sns-warning

  receivers:
    - name: default
      sns_configs:
        - topic_arn: ${sns_topic_arn}
          sigv4:
            region: ${region}

    - name: sns-critical
      sns_configs:
        - topic_arn: ${sns_critical_topic_arn}
          sigv4:
            region: ${region}

    - name: sns-high
      sns_configs:
        - topic_arn: ${sns_topic_arn}
          sigv4:
            region: ${region}

    - name: sns-warning
      sns_configs:
        - topic_arn: ${sns_topic_arn}
          sigv4:
            region: ${region}

    %{ if pagerduty_enabled }
    - name: pagerduty
      pagerduty_configs:
        - routing_key: ${pagerduty_routing_key}
          severity: critical
    %{ endif }

    %{ if slack_enabled }
    - name: slack
      slack_configs:
        - api_url: ${slack_api_url}
          channel: '${slack_channel}'
          send_resolved: true
          title: '{{ .GroupLabels.alertname }} - {{ .CommonLabels.severity }}'
          text: '{{ .CommonAnnotations.description }}'
    %{ endif }
