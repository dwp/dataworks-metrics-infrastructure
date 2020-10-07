global:
  external_labels:
    role: ${environment}
  scrape_interval: 1m
  scrape_timeout: 10s
  evaluation_interval: 1m
scrape_configs:
- job_name: ci
  honor_timestamps: true
  scrape_interval: 1m
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  ec2_sd_configs:
  - endpoint: ""
    region: eu-west-2
    refresh_interval: 1m
    port: 9090
    filters: []
  relabel_configs:
  - source_labels: [__meta_ec2_tag_Name]
    separator: ;
    regex: concourse-web
    replacement: $1
    action: keep
  - source_labels: [__meta_ec2_tag_Name, __meta_ec2_availability_zone]
    separator: ;
    regex: (.*)
    target_label: instance
    replacement: $1
    action: replace
- job_name: 'ecs-service-discovery'
  scrape_interval: 1m
  file_sd_configs:
    - files:
        - /prometheus/ecs/1m-tasks.json
  relabel_configs:
    - source_labels: [metrics_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
  metric_relabel_configs:
    - source_labels: [__name__]
      regex: 'application_[0-9]+_[0-9]+_(.*)'
      replacement: adg_$${1}
      target_label: __name__
      action: replace
      
