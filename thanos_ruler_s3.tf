data template_file "thanos_ruler" {
  template = file("${path.module}/config/thanos/rules/alert.rules.yaml")
}

resource "aws_s3_bucket_object" "thanos_ruler" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/thanos/rules/alert.rules.yaml"
  content    = data.template_file.thanos_ruler.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
