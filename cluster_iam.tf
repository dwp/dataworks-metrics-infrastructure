resource "aws_iam_role" "metrics_cluster" {
  name                 = "metrics_cluster"
  assume_role_policy   = data.aws_iam_policy_document.metrics_cluster_assume_role.json
  max_session_duration = local.iam_role_max_session_timeout_seconds
  tags                 = merge(local.tags, { Name = "metrics_cluster" })
}

resource "aws_iam_instance_profile" "metrics_cluster" {
  name = "metrics_cluster"
  role = aws_iam_role.metrics_cluster.name
}

data "aws_iam_policy_document" "metrics_cluster_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "metrics_cluster_read_config_attachment" {
  role       = aws_iam_role.metrics_cluster.name
  policy_arn = aws_iam_policy.metrics_cluster_read_config.arn
}

resource "aws_iam_policy" "metrics_cluster_read_config" {
  name        = "MetricsClusterReadConfigPolicy"
  description = "Allow metrics cluster to read from config bucket"
  policy      = data.aws_iam_policy_document.metrics_cluster_read_config.json
}

data "aws_iam_policy_document" "metrics_cluster_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn}",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "metrics_cluster_monitoring_bucket_read_write" {
  role       = aws_iam_role.metrics_cluster.name
  policy_arn = aws_iam_policy.metrics_cluster_monitoring_bucket_read_write.arn
}

resource "aws_iam_policy" "metrics_cluster_monitoring_bucket_read_write" {
  name        = "MetricsClusterBucketReadWritePolicy"
  description = "Allow metrics cluster to read and write to monitoring bucket"
  policy      = data.aws_iam_policy_document.monitoring_bucket_read_write.json
}

data "aws_iam_policy_document" "metrics_cluster_monitoring_bucket_read_write" {

  statement {
    sid    = "AllowUseDefaultEbsCmk"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [data.terraform_remote_state.security-tools.outputs.ebs_cmk.arn]
  }

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

resource "aws_iam_role_policy_attachment" "metrics_cluster_monitoring_logging" {
  role       = aws_iam_role.metrics_cluster.name
  policy_arn = aws_iam_policy.metrics_cluster_monitoring_logging.arn
}

resource "aws_iam_policy" "metrics_cluster_monitoring_logging" {
  name        = "MetricsClusterLoggingPolicy"
  description = "Allow Metrics cluster to log"
  policy      = data.aws_iam_policy_document.metrics_cluster_monitoring_logging.json
}

data "aws_iam_policy_document" "metrics_cluster_monitoring_logging" {
  statement {
    sid    = "AllowAccessLogGroups"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [aws_cloudwatch_log_group.metrics_ecs_cluster.arn]
  }
}

resource "aws_iam_role_policy_attachment" "metrics_cluster_monitoring_tagging" {
  role       = aws_iam_role.metrics_cluster.name
  policy_arn = aws_iam_policy.metrics_cluster_monitoring_tagging.arn
}

resource "aws_iam_policy" "metrics_cluster_monitoring_tagging" {
  name        = "MetricsClusterTaggingPolicy"
  description = "Allow Metrics cluster to modify tags"
  policy      = data.aws_iam_policy_document.metrics_cluster_monitoring_tagging.json
}

data "aws_iam_policy_document" "metrics_cluster_monitoring_tagging" {
  statement {
    sid    = "EnableEC2PermissionsHost"
    effect = "Allow"

    actions = [
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:*Tags",
    ]
    resources = ["arn:aws:ec2:${var.region}:${local.account[local.environment]}:instance/*"]
  }
}

resource "aws_iam_role_policy_attachment" "metrics_cluster_ecs_cwasp" {
  role       = aws_iam_role.metrics_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "metrics_cluster_ecs_ssm" {
  role       = aws_iam_role.metrics_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "metrics_cluster_ecs" {
  role       = aws_iam_role.metrics_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
