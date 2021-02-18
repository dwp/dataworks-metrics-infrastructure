data template_file "hbase_exporter" {
  count    = local.is_management_env ? 0 : 1
  template = file("${path.module}/config/json_exporter/hbase_config.yml")
  vars = {
    metrics_bucket = data.terraform_remote_state.common.outputs.published_bucket.id
    metrics_key    = "metrics/hbase-metrics.json"
  }
}

resource "aws_s3_bucket_object" "hbase_exporter" {
  count      = local.is_management_env ? 0 : 1
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/json_exporter/hbase_config.yml"
  content    = data.template_file.hbase_exporter[0].rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
