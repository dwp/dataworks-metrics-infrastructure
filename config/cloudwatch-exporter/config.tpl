discovery:
  jobs:
  - regions:
      - ${region}
    type: elb
    enableMetricData: true
    metrics:
      - name: ActiveConnectionCount
        statistics:
        - Sum
        period: 300
        length: 600
