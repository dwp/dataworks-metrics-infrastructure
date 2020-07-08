type: S3
config:
  bucket: "${metrics_bucket}"
  endpoint: "${s3_endpoint}"
  region: ""
  insecure: false
  signature_version2: false
  encrypt_sse: true
  put_user_metadata: {}
  http_config:
    idle_conn_timeout: 90s
    response_header_timeout: 2m
    insecure_skip_verify: false
  trace:
    enable: false
