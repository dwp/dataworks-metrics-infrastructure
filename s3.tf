data "aws_secretsmanager_secret" "dataworks_secrets" {
  count = local.is_management_env ? 1 : 0
  name  = "/concourse/dataworks/dataworks-secrets"
}

data "aws_secretsmanager_secret_version" "dataworks_secrets" {
  count     = local.is_management_env ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.dataworks_secrets[local.primary_role_index].id
}

data "aws_secretsmanager_secret" "dataworks" {
  count = local.is_management_env ? 1 : 0
  name  = "/concourse/dataworks/dataworks"
}

data "aws_secretsmanager_secret_version" "dataworks" {
  count     = local.is_management_env ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.dataworks[local.primary_role_index].id
}

resource "random_id" "monitoring_bucket" {
  count       = local.is_management_env ? 1 : 0
  byte_length = 16
}

resource "aws_kms_key" "monitoring_bucket_cmk" {
  count                   = local.is_management_env ? 1 : 0
  description             = "Monitoring Bucket Master Key"
  deletion_window_in_days = 7
  is_enabled              = true
  enable_key_rotation     = true
  tags = merge(
    local.tags,
    map("Name", "Monitoring bucket key"),
    map("ProtectsSensitiveData", "False")
  )
}

resource "aws_kms_alias" "monitoring_bucket_cmk_alias" {
  count         = local.is_management_env ? 1 : 0
  target_key_id = aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].key_id
  name          = "alias/monitoring_bucket_cmk"
}

resource "aws_s3_bucket" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = random_id.monitoring_bucket[local.primary_role_index].hex
  acl    = "private"
  tags = merge(
    local.tags,
    map("Name", "Metrics Store")
  )

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = aws_s3_bucket.monitoring[local.primary_role_index].id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

data "aws_iam_policy_document" "monitoring_bucket_enforce_https" {
  count = local.is_management_env ? 1 : 0
  statement {
    sid     = "BlockHTTP"
    effect  = "Deny"
    actions = ["*"]

    resources = [
      aws_s3_bucket.monitoring[local.primary_role_index].arn,
      "${aws_s3_bucket.monitoring[local.primary_role_index].arn}/*",
    ]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket_policy" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = aws_s3_bucket.monitoring[local.primary_role_index].id
  policy = local.is_management_env ? data.aws_iam_policy_document.monitoring_bucket_enforce_https[local.primary_role_index].json : "{}"
}

data template_file "prometheus" {
  template = file("${path.module}/config/prometheus/prometheus-slave.tpl")
  vars = {
    parent_domain_name = var.parent_domain_name
  }
}

data template_file "thanos_query" {
  template = file("${path.module}/config/thanos/bucket.tpl")
  vars = {
    metrics_bucket = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].id : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.id
    s3_endpoint    = "s3-${var.region}.amazonaws.com"
  }
}

data template_file "thanos_ruler" {
  template = file("${path.module}/config/thanos/rules/alert.rules.yaml")
}

data template_file "grafana" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/config/grafana/grafana.tpl")
  vars = {
    grafana_user     = jsondecode(data.aws_secretsmanager_secret_version.dataworks_secrets[local.primary_role_index].secret_binary)["grafana_user"]
    grafana_password = jsondecode(data.aws_secretsmanager_secret_version.dataworks_secrets[local.primary_role_index].secret_binary)["grafana_password"]
    grafana_domain   = aws_route53_record.grafana_loadbalancer[0].fqdn
    client_id        = aws_cognito_user_pool_client.grafana[0].id
    client_secret    = aws_cognito_user_pool_client.grafana[0].client_secret
    cognito_domain   = data.terraform_remote_state.aws_concourse.outputs.cognito.user_pool_domain
    region           = var.region
  }
}

data template_file "grafana_datasource_config" {
  template = file("${path.module}/config/grafana/provisioning/datasources/datasource.tpl")
  vars = {
    thanos_query_hostname = "thanos-query.${local.environment}.services.${var.parent_domain_name}"
  }
}

data template_file "grafana_dashboard_config" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/dashboards.tpl")
}

data template_file "grafana_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/dashboard.json")
}

data template_file "alertmanager" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/config/alertmanager/config.yml")
  vars = {
    slack_api_url = jsondecode(data.aws_secretsmanager_secret_version.dataworks[local.primary_role_index].secret_binary)["slack_webhook_url"]
    http_proxy    = "http://${aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name}:3128"
  }
}

data template_file "outofband" {
  template = file("${path.module}/config/prometheus/prometheus-outofband.tpl")
  vars = {
    parent_domain_name = var.parent_domain_name
    environment        = local.environment
  }
}

data template_file "outofband_rules" {
  template = file("${path.module}/config/prometheus/outofband-rules.tpl")
}

resource "aws_s3_bucket_object" "prometheus" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/prometheus-slave.yml"
  content    = data.template_file.prometheus.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "thanos_query" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/thanos/bucket.yml"
  content    = data.template_file.thanos_query.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "thanos_ruler" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/thanos/rules/alert.rules.yaml"
  content    = data.template_file.thanos_ruler.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "grafana" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/grafana.ini"
  content    = data.template_file.grafana[local.primary_role_index].rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "grafana_datasource_config" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/datasources/datasource.yaml"
  content    = data.template_file.grafana_datasource_config.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "grafana_dashboard_config" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/dashboards.yaml"
  content    = data.template_file.grafana_dashboard_config.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "grafana_dashboard" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/provisioning/dashboards/dashboard.json"
  content    = data.template_file.grafana_dashboard.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "alertmanager" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/alertmanager/config.yml"
  content    = data.template_file.alertmanager.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "outofband" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/prometheus-outofband.yml"
  content    = data.template_file.outofband.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "outofband_rules" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/outofband-rules.yml"
  content    = data.template_file.outofband_rules.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
