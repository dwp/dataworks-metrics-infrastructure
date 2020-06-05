global:
  scrape_interval: 15s
  evaluation_interval: 30s
  # scrape_timeout is set to the global default (10s).

scrape_configs:
  - job_name: 'federate'
    scrape_interval: 15s

    honor_labels: true
    metrics_path: '/federate'

    params:
      'match[]':
        - '{job="prometheus"}'
        - '{__name__=~"job:.*"}'

    static_configs:
      - targets:
        - 'prometheus-slave:9090'
