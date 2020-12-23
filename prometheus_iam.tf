resource "aws_iam_role" "prometheus" {
  name               = "prometheus"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role.json
  tags               = merge(local.tags, { Name = "prometheus" })
}

resource "aws_iam_instance_profile" "prometheus" {
  name = "prometheus-instance"
  role = aws_iam_role.prometheus.name
}

data "aws_iam_policy_document" "prometheus_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_read_config_attachment" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_read_config.arn
}

resource "aws_iam_policy" "prometheus_read_config" {
  name        = "PrometheusReadConfigPolicy"
  description = "Allow Prometheus to read from config bucket"
  policy      = data.aws_iam_policy_document.prometheus_read_config.json
}

data "aws_iam_policy_document" "prometheus_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/thanos/*",
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/prometheus/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn}",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_service_discovery_attachment" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_service_discovery.arn
}

resource "aws_iam_policy" "prometheus_service_discovery" {
  name        = "PrometheusServiceDiscoveryPolicy"
  description = "Allow Prometheus to perform service discovery"
  policy      = data.aws_iam_policy_document.prometheus_service_discovery.json
}

data "aws_iam_policy_document" "prometheus_service_discovery" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:Describe*",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:CreateTags",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolumeAttribute"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:Describe*",
      "ecs:List*",
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_efs_attachment" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_efs.arn
}

resource "aws_iam_policy" "prometheus_efs" {
  name        = "PrometheusEFSPolicy"
  description = "Allow Prometheus to access EFS volume"
  policy      = data.aws_iam_policy_document.prometheus_efs.json
}

data "aws_iam_policy_document" "prometheus_efs" {
  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.prometheus_new.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_monitoring_bucket_read_write" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.monitoring_bucket_read_write.arn
}

resource "aws_iam_policy" "monitoring_bucket_read_write" {
  name        = "MonitoringBucketReadWritePolicy"
  description = "Allow Prometheus to read and write to monitoring bucket"
  policy      = data.aws_iam_policy_document.monitoring_bucket_read_write.json
}

data "aws_iam_policy_document" "monitoring_bucket_read_write" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject"
    ]

    resources = [
      "${local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.arn}",
      "${local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [
      "${local.is_management_env ? aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.key}",
    ]
  }
}
