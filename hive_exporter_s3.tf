data template_file "hive_exporter" {
  count = local.is_management_env ? 0 : 1
  template = file("${path.module}/config/hive_exporter/config.yml")
  vars = {
    metrics_bucket = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.published_bucket.id
    metrics_key    = "metrics/pdm-metrics.json"
  }
}

resource "aws_s3_bucket_object" "hive_exporter" {
  count      = local.is_management_env ? 0 : 1
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/hive_exporter/config.yml"
  content    = data.template_file.hive_exporter[0].rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
