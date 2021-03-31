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

data template_file "pdm_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/pdm_dashboard.json")
}

data template_file "analytical_emr_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/analytical_emr_dashboard.json")
}

data template_file "concourse_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/concourse_dashboard.json")
}

data template_file "HDFS_DataNode" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/HDFS-DataNode.json")
}

data template_file "HDFS_NameNode" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/HDFS-NameNode.json")
}

data template_file "JVM_Metrics" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/JVM_Metrics.json")
}

data template_file "Log_Metrics" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/Log_Metrics.json")
}

data template_file "OS_Level_Metrics" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/OS_Level_Metrics.json")
}

data template_file "RPC_Metrics" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/RPC_Metrics.json")
}

data template_file "YARN_Node_Manager" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/YARN-Node_Manager.json")
}

data template_file "htme_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/htme_dashboard.json")
}

resource "aws_s3_bucket_object" "grafana" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/grafana.ini"
  content    = data.template_file.grafana[local.primary_role_index].rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "status_check" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/status_check.sh"
  content    = file("${path.module}/config/grafana/status_check.sh")
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
# private dashboards
resource "aws_s3_bucket_object" "security_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/security_dashboard.json"
  content    = data.template_file.security_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "adg_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/adg_dashboard.json"
  content    = data.template_file.adg_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "pdm_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/pdm_dashboard.json"
  content    = data.template_file.pdm_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "analytical_emr_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/analytical_emr_dashboard.json"
  content    = data.template_file.analytical_emr_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "concourse_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/concourse_dashboard.json"
  content    = data.template_file.concourse_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "HDFS_DataNode" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/EMR/HDFS-DataNode.json"
  content    = data.template_file.HDFS_DataNode.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "HDFS_NameNode" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/EMR/HDFS_NameNode.json"
  content    = data.template_file.HDFS_NameNode.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "JVM_Metrics" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/EMR/JVM_Metrics.json"
  content    = data.template_file.JVM_Metrics.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "Log_Metrics" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/EMR/Log_Metrics.json"
  content    = data.template_file.Log_Metrics.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "OS_Level_Metrics" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/EMR/OS_Level_Metrics.json"
  content    = data.template_file.OS_Level_Metrics.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "RPC_Metrics" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/EMR/RPC_Metrics.json"
  content    = data.template_file.RPC_Metrics.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "YARN_Node_Manager" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/EMR/YARN_Node_Manager.json"
  content    = data.template_file.YARN_Node_Manager.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}

resource "aws_s3_bucket_object" "htme_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/private/htme_dashboard.json"
  content    = data.template_file.htme_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
  tags       = merge(local.tags, { Name = var.name })
}
