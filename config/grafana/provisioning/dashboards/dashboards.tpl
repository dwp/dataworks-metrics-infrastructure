apiVersion: 1

providers:
- name: 'Prometheus'
  orgId: 1
  type: file
  disableDeletion: true
  editable: true
  options:
    path: /etc/grafana/provisioning/dashboards
