resource "aws_iam_role" "cloudwatch_exporter" {
  name               = "cloudwatch-exporter"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_exporter_assume_role.json
  tags               = merge(local.tags, { Name = "cloudwatch-exporter" })
}

data "aws_iam_policy_document" "cloudwatch_exporter_assume_role" {
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

resource "aws_iam_role_policy_attachment" "cloudwatch_exporter_read_config_attachment" {
  role       = aws_iam_role.cloudwatch_exporter.name
  policy_arn = aws_iam_policy.cloudwatch_exporter_read_config.arn
}

resource "aws_iam_policy" "cloudwatch_exporter_read_config" {
  name        = "CloudwatchExporterReadConfigPolicy"
  description = "Allow Cloudwatch Exporter to read from config bucket"
  policy      = data.aws_iam_policy_document.cloudwatch_exporter_read_config.json
}

data "aws_iam_policy_document" "cloudwatch_exporter_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/cloudwatch-exporter/*",
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

resource "aws_iam_role_policy_attachment" "cloudwatch_exporter_read_cloudwatch_attachment" {
  role       = aws_iam_role.cloudwatch_exporter.name
  policy_arn = aws_iam_policy.cloudwatch_exporter_read_cloudwatch.arn
}

resource "aws_iam_policy" "cloudwatch_exporter_read_cloudwatch" {
  name        = "CloudwatchExporterReadCloudwatchPolicy"
  description = "Allow Cloudwatch Exporter to read from cloudwatch"
  policy      = data.aws_iam_policy_document.cloudwatch_exporter_read_cloudwatch.json
}

data "aws_iam_policy_document" "cloudwatch_exporter_read_cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics"
    ]

    resources = [
      "*",
    ]
  }
}
