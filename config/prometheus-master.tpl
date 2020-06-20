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
      - targets: ['monitoring-slave.development.services.${parent_domain_name}:9090']
        labels:
          group: 'development-slave'
      - targets: ['monitoring-slave.management-dev.services.${parent_domain_name}:9090']
        labels:
          group: 'management-dev-slave'
