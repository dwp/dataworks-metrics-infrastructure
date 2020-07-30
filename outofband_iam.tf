resource "aws_iam_role" "outofband" {
  count              = local.is_management_env ? 1 : 0
  name               = "outofband"
  assume_role_policy = data.aws_iam_policy_document.outofband_assume_role.json
  tags               = merge(local.tags, { Name = "outofband" })
}

data "aws_iam_policy_document" "outofband_assume_role" {
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

resource "aws_iam_role_policy_attachment" "outofband_read_config_attachment" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.outofband[local.primary_role_index].name
  policy_arn = aws_iam_policy.outofband_read_config[local.primary_role_index].arn
}

resource "aws_iam_policy" "outofband_read_config" {
  count       = local.is_management_env ? 1 : 0
  name        = "OutofbandReadConfigPolicy"
  description = "Allow Outofband to read from config bucket"
  policy      = data.aws_iam_policy_document.outofband_read_config.json
}

data "aws_iam_policy_document" "outofband_read_config" {
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

resource "aws_iam_role_policy_attachment" "outofband_efs_attachment" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.outofband[local.primary_role_index].name
  policy_arn = aws_iam_policy.outofband_efs[local.primary_role_index].arn
}

resource "aws_iam_policy" "outofband_efs" {
  count       = local.is_management_env ? 1 : 0
  name        = "OutofbandEFSPolicy"
  description = "Allow Prometheus to access EFS volume"
  policy      = data.aws_iam_policy_document.outofband_efs[local.primary_role_index].json
}

data "aws_iam_policy_document" "outofband_efs" {
  count = local.is_management_env ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.outofband[local.primary_role_index].arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "outofband_monitoring_bucket_read_write" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.outofband[local.primary_role_index].name
  policy_arn = aws_iam_policy.monitoring_bucket_read_write.arn
}

