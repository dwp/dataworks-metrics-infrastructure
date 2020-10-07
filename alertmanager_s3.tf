
data template_file "alertmanager" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/config/alertmanager/config.yml")
  vars = {
    slack_api_url = jsondecode(data.aws_secretsmanager_secret_version.dataworks[local.primary_role_index].secret_binary)["slack_webhook_url"]
    http_proxy    = "http://${aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name}:3128"
  }
}

resource "aws_s3_bucket_object" "alertmanager" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/alertmanager/config.yml"
  content    = data.template_file.alertmanager[local.primary_role_index].rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
