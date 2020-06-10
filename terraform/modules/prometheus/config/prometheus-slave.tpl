scrape_configs:
  - job_name: 'ci'

    metrics_path: /metrics

    static_configs:
      - targets: ['127.0.0.1:9090']
        labels:
          group: 'concourse'
