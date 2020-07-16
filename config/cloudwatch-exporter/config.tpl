---
region: eu-west-2
metrics:
- aws_namespace: AWS/ELB
  aws_metric_name: HealthyHostCount
  aws_dimensions: [AvailabilityZone, LoadBalancerName]
  aws_statistics: [Average]
