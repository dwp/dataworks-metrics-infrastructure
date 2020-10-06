data template_file "cloudwatch_exporter" {
  template = file("${path.module}/config/cloudwatch_exporter/config.yml")
  vars = {
    region = var.region
  }
}

resource "aws_s3_bucket_object" "cloudwatch_exporter" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/cloudwatch_exporter/config.yml"
  content    = data.template_file.cloudwatch_exporter.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
