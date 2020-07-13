groups:
- name: alert.rules
  rules:
  - alert: OutOfBandSimpleAlert
    annotations:
      message: Simple alert to test outofband alerting
    expr: up == 1
    for: 15s
    labels:
      severity: warning
