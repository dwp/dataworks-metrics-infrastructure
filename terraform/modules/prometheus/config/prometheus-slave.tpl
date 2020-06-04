global:
  scrape_interval: 15s
  evaluation_interval: 30s
  # scrape_timeout is set to the global default (10s).

scrape_configs:
   - targets: ['ci.wip.dataworks.dwp.gov.uk:9100/metrics]
        labels:
          group: 'concourse'
