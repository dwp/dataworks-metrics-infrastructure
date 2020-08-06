data template_file "prometheus" {
  template = file("${path.module}/config/prometheus/prometheus-slave.tpl")
  vars = {
    parent_domain_name = var.parent_domain_name
    environment = local.environment
  }
}

resource "aws_s3_bucket_object" "prometheus" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/prometheus-slave.yml"
  content    = data.template_file.prometheus.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
