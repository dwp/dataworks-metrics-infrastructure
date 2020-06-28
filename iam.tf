resource "aws_iam_role" "prometheus" {
  name               = "prometheus"
  assume_role_policy = data.aws_iam_policy_document.prometheus.json
  tags               = merge(local.tags, { Name = "prometheus" })
}

data "aws_iam_policy_document" "prometheus" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/*",
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

  statement {
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      "${local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.arn}",
      "${local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeTags",
      "ec2:DescribeSnapshots",
      "elasticfilesystem:*"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "prometheus" {
  policy = data.aws_iam_policy_document.prometheus_read_config.json
  role   = aws_iam_role.prometheus.id
}
