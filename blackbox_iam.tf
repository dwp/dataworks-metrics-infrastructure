resource "aws_iam_role" "blackbox" {
  count              = local.is_management_env ? 0 : 1
  name               = "blackbox"
  assume_role_policy = data.aws_iam_policy_document.blackbox_assume_role.json
  tags               = merge(local.tags, { Name = "blackbox" })
}

data "aws_iam_policy_document" "blackbox_assume_role" {
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

resource "aws_iam_role_policy_attachment" "blackbox_read_config_attachment" {
  count      = local.is_management_env ? 0 : 1
  role       = aws_iam_role.blackbox[local.primary_role_index].name
  policy_arn = aws_iam_policy.blackbox_read_config[local.primary_role_index].arn
}

resource "aws_iam_policy" "blackbox_read_config" {
  count       = local.is_management_env ? 0 : 1
  name        = "BlackboxReadConfigPolicy"
  description = "Allow Blackbox to read from config bucket"
  policy      = data.aws_iam_policy_document.blackbox_read_config.json
}

data "aws_iam_policy_document" "blackbox_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/blackbox/*",
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

resource "aws_iam_role_policy_attachment" "blackbox_ecs_exec" {
  count      = local.is_management_env ? 0 : 1
  role       = aws_iam_role.blackbox[local.primary_role_index].name
  policy_arn = aws_iam_policy.blackbox_ecs_exec[local.primary_role_index].arn
}

resource "aws_iam_policy" "blackbox_ecs_exec" {
  count       = local.is_management_env ? 0 : 1
  name        = "BlackboxECSExecPolicy"
  description = "Allow Blackbox container to exec from cli"
  policy      = data.aws_iam_policy_document.blackbox_ecs_exec.json
}

data "aws_iam_policy_document" "blackbox_ecs_exec" {
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
