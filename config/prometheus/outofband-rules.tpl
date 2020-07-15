groups:
- name: outofbandalert.rules
  rules:
  - alert: ThanosRulerAlertSendFailure
    annotations:
      title: Thanos Ruler alert dropped
      description: Thanos ruler failed to send alert to alertmanager, possible connectivity issue.
    expr: rate(thanos_alert_sender_alerts_dropped_total[30s]) > 0
    for: 0s
    labels:
      severity: warning

  - alert: ThanosRulerEvaluationFailure
    annotations:
      title: Thanos Ruler failed to evaluate rule
      description: Thanos ruler failed to evaluate a rule indicating possible query API issue on Thanos query node. 
    expr: rate(prometheus_rule_evaluation_failures_total[30s]) > 0
    for: 0s
    labels:
      severity: warning

  - alert: ThanosRulerSlowEvaluation
    annotations:
      title: Thanos Ruler is performing slow evaluation
      description: Thanos ruler is taking too long to evaluate rules, so not all rules are being evaluated, correct issue or increate evaluation interval.
    expr: prometheus_rule_group_interval_seconds < prometheus_rule_group_last_duration_seconds
    for: 0s
    labels:
      severity: warning

  - alert: ThanosRulerEvaluationWarnings
    annotations:
      title: Thanos ruler failed to send alert to alertmanager
      description: Thanos ruler failed to send alert to alertmanager, possible connectivity issue.
    expr: rate(thanos_rule_evaluation_with_warnings_total[30s]) > 0
    for: 0s
    labels:
      severity: warning
