resource "aws_iam_role" "hbase_exporter" {
  count              = local.is_management_env ? 0 : 1
  name               = "hbase-exporter"
  assume_role_policy = data.aws_iam_policy_document.hbase_exporter_assume_role[0].json
  tags               = merge(local.tags, { Name = "hbase-exporter" })
}

data "aws_iam_policy_document" "hbase_exporter_assume_role" {
  count = local.is_management_env ? 0 : 1
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

resource "aws_iam_role_policy_attachment" "hbase_exporter_read_config_attachment" {
  count      = local.is_management_env ? 0 : 1
  role       = aws_iam_role.hbase_exporter[local.primary_role_index].name
  policy_arn = aws_iam_policy.hbase_exporter_read_config[local.primary_role_index].arn
}

resource "aws_iam_policy" "hbase_exporter_read_config" {
  count       = local.is_management_env ? 0 : 1
  name        = "HbaseReadConfigPolicy"
  description = "Allow Grafana to read from config bucket"
  policy      = data.aws_iam_policy_document.hbase_exporter_read_config[0].json
}

data "aws_iam_policy_document" "hbase_exporter_read_config" {
  count = local.is_management_env ? 0 : 1
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/hbase_exporter/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "hbase_exporter_read_metrics_attachment" {
  count      = local.is_management_env ? 0 : 1
  role       = aws_iam_role.hbase_exporter[local.primary_role_index].name
  policy_arn = aws_iam_policy.hbase_exporter_read_metrics[local.primary_role_index].arn
}

resource "aws_iam_policy" "hbase_exporter_read_metrics" {
  count       = local.is_management_env ? 0 : 1
  name        = "HbaseExporterReadMetricsPolicy"
  description = "Allow PDM Exporter to read from published bucket"
  policy      = data.aws_iam_policy_document.hbase_exporter_read_metrics[0].json
}

data "aws_iam_policy_document" "hbase_exporter_read_metrics" {
  count = local.is_management_env ? 0 : 1
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.aws_analytical_dataset_generation.outputs.published_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${data.terraform_remote_state.aws_analytical_dataset_generation.outputs.published_bucket.arn}/metrics/hbase-metrics.json",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      data.terraform_remote_state.aws_analytical_dataset_generation.outputs.published_bucket_cmk.arn,
    ]
  }
}
