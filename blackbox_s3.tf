data template_file "blackbox_nifi" {
  template = file("${path.module}/config/blackbox/blackbox-nifi.yml")
  vars = {
    parent_domain_name = var.parent_domain_name
    environment        = local.environment
  }
}

resource "aws_s3_bucket_object" "blackbox_nifi" {
  count      = local.is_management_env ? 0 : 1
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/blackbox/blackbox-nifi.yml"
  content    = data.template_file.blackbox_nifi.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
