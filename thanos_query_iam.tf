resource "aws_iam_role" "thanos_query" {
  count              = local.is_management_env ? 1 : 0
  name               = "thanos-query"
  assume_role_policy = data.aws_iam_policy_document.thanos_query_assume_role.json
  tags               = merge(local.tags, { Name = "thanos-query" })
}

data "aws_iam_policy_document" "thanos_query_assume_role" {
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

resource "aws_iam_role_policy_attachment" "thanos_query_read_config_attachment" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.thanos_query[local.primary_role_index].name
  policy_arn = aws_iam_policy.thanos_query_read_config[local.primary_role_index].arn
}

resource "aws_iam_policy" "thanos_query_read_config" {
  count       = local.is_management_env ? 1 : 0
  name        = "ThanosQueryReadConfigPolicy"
  description = "Allow Thanos to read from config bucket"
  policy      = data.aws_iam_policy_document.thanos_query_read_config.json
}

data "aws_iam_policy_document" "thanos_query_read_config" {
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

resource "aws_iam_role_policy_attachment" "thanos_query_ecs_exec" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.thanos_query[local.primary_role_index].name
  policy_arn = aws_iam_policy.thanos_query_ecs_exec[local.primary_role_index].arn
}

resource "aws_iam_policy" "thanos_query_ecs_exec" {
  count       = local.is_management_env ? 1 : 0
  name        = "ThanosQueryECSExecPolicy"
  description = "Allow ThanosQuery container to exec from cli"
  policy      = data.aws_iam_policy_document.thanos_query_ecs_exec.json
}

data "aws_iam_policy_document" "thanos_query_ecs_exec" {
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
