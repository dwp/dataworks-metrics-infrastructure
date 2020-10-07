data template_file "grafana" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/config/grafana/grafana.ini")
  vars = {
    grafana_domain = aws_route53_record.grafana_loadbalancer[0].fqdn
    client_id      = aws_cognito_user_pool_client.grafana[0].id
    client_secret  = aws_cognito_user_pool_client.grafana[0].client_secret
    cognito_domain = data.terraform_remote_state.aws_concourse.outputs.cognito.user_pool_domain
    region         = var.region
  }
}

data template_file "grafana_datasource_config" {
  template = file("${path.module}/config/grafana/provisioning/datasources/datasource.yaml")
  vars = {
    thanos_query_hostname = "thanos-query.${local.environment}.services.${var.parent_domain_name}"
  }
}

data template_file "grafana_dashboard_config" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/dashboards.tpl")
}

data template_file "security_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/security_dashboard.json")
}

data template_file "adg_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/adg_dashboard.json")
}

data template_file "analytical_emr_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/analytical_emr_dashboard.json")
}


resource "aws_s3_bucket_object" "grafana" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/grafana.ini"
  content    = data.template_file.grafana[local.primary_role_index].rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "grafana_datasource_config" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/datasources/datasource.yaml"
  content    = data.template_file.grafana_datasource_config.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "grafana_dashboard_config" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/dashboards.yaml"
  content    = data.template_file.grafana_dashboard_config.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "security_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/security_dashboard.json"
  content    = data.template_file.security_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "adg_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/adg_dashboard.json"
  content    = data.template_file.adg_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "analytical_emr_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/analytical_emr_dashboard.json"
  content    = data.template_file.analytical_emr_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
