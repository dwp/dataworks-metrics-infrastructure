data template_file "blackbox" {
  template = file("${path.module}/config/blackbox/blackbox.yml")
  vars = {
    parent_domain_name = var.parent_domain_name
    environment        = local.environment
  }
}

resource "aws_s3_bucket_object" "blackbox" {
  count      = local.is_management_env ? 1 : 1
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/blackbox/blackbox.yml"
  content    = data.template_file.blackbox.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
