resource "random_id" "monitoring_bucket" {
  count       = local.is_management_env ? 1 : 0
  byte_length = 16
}

resource "aws_s3_bucket" "monitoring" {
  count  = local.is_management_env ? 1 : 0
  bucket = random_id.monitoring_bucket[local.primary_role_index].hex
  acl    = "private"
  tags   = local.tags
  versioning {
    enabled = false
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
  count    = length(local.roles)
  template = file("${path.module}/config/prometheus/prometheus-${local.roles[count.index]}.tpl")
  vars = {
    parent_domain_name = var.parent_domain_name
  }
}

data template_file "thanos" {
  template = file("${path.module}/config/thanos/bucket.tpl")
  vars = {
    metrics_bucket = local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].id : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.id
    s3_endpoint    = "s3-${var.region}.amazonaws.com"
  }
}

data template_file "grafana" {
  template = file("${path.module}/config/grafana/grafana.tpl")
}

data template_file "grafana_datasource_config" {
  template = file("${path.module}/config/grafana/provisioning/datasources/datasource.tpl")
  vars = {
    thanos_query_hostname = "thanos.${local.environment}.services.${var.parent_domain_name}"
  }
}

data template_file "grafana_dashboard_config" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/dashboards.tpl")
}

data template_file "grafana_dashboard" {
  template = file("${path.module}/config/grafana/provisioning/dashboards/dashboard.json")
}

resource "aws_s3_bucket_object" "prometheus" {
  count      = length(local.roles)
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/prometheus/prometheus-${local.roles[count.index]}.yml"
  content    = data.template_file.prometheus[count.index].rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "thanos" {
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/thanos/bucket.yml"
  content    = data.template_file.thanos.rendered
  kms_key_id = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "grafana" {
  count      = local.is_management_env ? 1 : 0
  bucket     = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${var.name}/grafana/grafana.ini"
  content    = data.template_file.grafana.rendered
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
