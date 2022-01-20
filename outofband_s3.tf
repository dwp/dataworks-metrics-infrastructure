data "template_file" "outofband" {
  template = file("${path.module}/config/prometheus/prometheus-outofband.yml")
  vars = {
    parent_domain_name = var.parent_domain_name
    environment        = local.environment
  }
}

data "template_file" "outofband_rules" {
  template = file("${path.module}/config/prometheus/outofband-rules.yml")
}


resource "aws_s3_bucket_object" "outofband" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/prometheus-outofband.yml"
  content    = data.template_file.outofband.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "outofband_rules" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/outofband-rules.yml"
  content    = data.template_file.outofband_rules.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
