resource "aws_iam_role" "alertmanager" {
  count              = local.is_management_env ? 1 : 0
  name               = "alertmanager"
  assume_role_policy = data.aws_iam_policy_document.alertmanager_assume_role.json
  tags               = merge(local.tags, { Name = "alertmanager" })
}

data "aws_iam_policy_document" "alertmanager_assume_role" {
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

resource "aws_iam_role_policy_attachment" "alertmanager_read_config_attachment" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.alertmanager[local.primary_role_index].name
  policy_arn = aws_iam_policy.alertmanager_read_config[local.primary_role_index].arn
}

resource "aws_iam_policy" "alertmanager_read_config" {
  count       = local.is_management_env ? 1 : 0
  name        = "AlertmanagerReadConfigPolicy"
  description = "Allow Alertmanager to read from config bucket"
  policy      = data.aws_iam_policy_document.alertmanager_read_config.json
}

data "aws_iam_policy_document" "alertmanager_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/alertmanager/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "alertmanager_ecs_exec" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.alertmanager[local.primary_role_index].name
  policy_arn = aws_iam_policy.alertmanager_ecs_exec[local.primary_role_index].arn
}

resource "aws_iam_policy" "alertmanager_ecs_exec" {
  count       = local.is_management_env ? 1 : 0
  name        = "AlertmanagerECSExecPolicy"
  description = "Allow Alertmanager container to exec from cli"
  policy      = data.aws_iam_policy_document.alertmanager_ecs_exec.json
}

data "aws_iam_policy_document" "alertmanager_ecs_exec" {
  statement {
    effect = "Allow"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = [
      "*",
    ]
  }
}
