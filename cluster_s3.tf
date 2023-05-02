data "local_file" "metrics_logrotate_script" {
  filename = "files/metrics.logrotate"
}

resource "aws_s3_object" "metrics_logrotate_script" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/metrics/metrics.logrotate"
  content    = data.local_file.metrics_logrotate_script.content
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket_cmk.arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn



  tags = merge(
    local.tags,
    {
      Name = "metrics-logrotate-script"
    },
  )
}

data "local_file" "metrics_cloudwatch_script" {
  filename = "files/metrics_cloudwatch.sh"
}

resource "aws_s3_object" "metrics_cloudwatch_script" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/metrics/metrics-cloudwatch.sh"
  content    = data.local_file.metrics_cloudwatch_script.content
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket_cmk.arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.tags,
    {
      Name = "metrics-cloudwatch-script"
    },
  )
}

data "local_file" "metrics_logging_script" {
  filename = "files/logging.sh"
}

resource "aws_s3_object" "metrics_logging_script" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/metrics/logging.sh"
  content    = data.local_file.metrics_logging_script.content
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket_cmk.arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.tags,
    {
      Name = "metrics-logging-script"
    },
  )
}

data "local_file" "metrics_config_hcs_script" {
  filename = "files/config_hcs.sh"
}

resource "aws_s3_object" "metrics_config_hcs_script" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/metrics/config-hcs.sh"
  content    = data.local_file.metrics_config_hcs_script.content
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket_cmk.arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.tags,
    {
      Name = "metrics-config-hcs-script"
    },
  )
}