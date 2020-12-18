data template_file "thanos_config" {
  template = file("${path.module}/config/thanos/bucket.yml")
  vars = {
    metrics_bucket = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].id : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.id
    s3_endpoint    = "s3-${var.region}.amazonaws.com"
    kms_key_id     = local.is_management_env ? aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.key
  }
}

resource "aws_s3_bucket_object" "thanos_config" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/thanos/bucket.yml"
  content    = data.template_file.thanos_config.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

data template_file "thanos_ruler" {
  template = file("${path.module}/config/thanos/rules/alert.rules.yaml")
}

resource "aws_s3_bucket_object" "thanos_ruler" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/thanos/rules/alert.rules.yaml"
  content    = data.template_file.thanos_ruler.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
