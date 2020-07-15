groups:
- name: outofbandalert.rules
  rules:
  - alert: ThanosRulerAlertSendFailure
    annotations:
      message: Thanos ruler failed to send alert to alertmanager
    expr: rate(thanos_alert_sender_alerts_dropped_total[30s]) > 0
    for: 0s
    labels:
      severity: warning

  - alert: ThanosRulerEvaluationFailure
    annotations:
      message: Thanos ruler failed to evaluate rule indication possible query API issue
    expr: rate(prometheus_rule_evaluation_failures_total[30s]) > 0
    for: 0s
    labels:
      severity: warning

  - alert: ThanosRulerSlowEvaluation
    annotations:
      message: Thanos ruler is taking longer to evaluate than specified evaluation interval
    expr: prometheus_rule_group_interval_seconds < prometheus_rule_group_last_duration_seconds
    for: 0s
    labels:
      severity: warning

  - alert: ThanosRulerEvaluationWarnings
    annotations:
      message: Thanos ruler failed to send alert to alertmanager
    expr: rate(thanos_rule_evaluation_with_warnings_total[30s]) > 0
    for: 0s
    labels:
      severity: warning
