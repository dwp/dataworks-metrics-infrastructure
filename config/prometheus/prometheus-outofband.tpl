global:
  external_labels:
    role: outofband

scrape_configs:
- job_name: 'outofband'
  scrape_interval: 15s

  static_configs:
  - targets: ['thanos-ruler.${environment}.services.${parent_domain_name}:9090']
    labels:
      group: 'outofband'
