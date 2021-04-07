data template_file "prometheus" {
  template = file("${path.module}/config/prometheus/prometheus-slave.yml")
  vars = {
    parent_domain_name = var.parent_domain_name
    environment        = local.environment
  }
}

resource "aws_s3_bucket_object" "prometheus" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/prometheus-slave.yml"
  content    = data.template_file.prometheus.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

data template_file "cloudwatch_agent" {
  template = file("${path.module}/config/cloudwatch_agent/config.json")
}

data template_file "cloudwatch_agent_prom" {
  template = file("${path.module}/config/cloudwatch_agent/prometheus.yaml")
}

resource "aws_s3_bucket_object" "cloudwatch_agent" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/cloudwatch_agent/config.json"
  content    = data.template_file.cloudwatch_agent.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "cloudwatch_agent_prom" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/cloudwatch_agent/prometheus.yaml"
  content    = data.template_file.cloudwatch_agent_prom.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
