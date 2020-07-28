static:
  - namespace: EMR/Collections
    name: collections
    regions:
      - ${region}
    metrics:
      - name: AllCollectionsProcessingTime
        statistics:
        - Minimum
        period: 60
        length: 300
