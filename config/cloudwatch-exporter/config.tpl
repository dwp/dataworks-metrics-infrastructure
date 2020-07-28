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
  - namespace: AWS/EC2
    name: security
    regions:
      - ${region}
    metrics:
      - name: MetadataNoToken
        statistics:
        - Maximum
        period: 60
        length: 300
