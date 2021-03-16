resource "aws_iam_role" "sdx_pushgateway" {
  count              = local.is_management_env ? 0 : 1
  name               = "sdx-pushgateway"
  assume_role_policy = data.aws_iam_policy_document.sdx_pushgateway_assume_role.json
  tags               = merge(local.tags, { Name = "sdx-pushgateway" })
}

data "aws_iam_policy_document" "sdx_pushgateway_assume_role" {
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

resource "aws_iam_role_policy_attachment" "sdx_pushgateway_ecs_exec" {
  count      = local.is_management_env ? 0 : 1
  role       = aws_iam_role.sdx_pushgateway[local.primary_role_index].name
  policy_arn = aws_iam_policy.sdx_pushgateway_ecs_exec[local.primary_role_index].arn
}

resource "aws_iam_policy" "sdx_pushgateway_ecs_exec" {
  count       = local.is_management_env ? 0 : 1
  name        = "SDXPushgatewayECSExecPolicy"
  description = "Allow SDXPushgateway container to exec from cli"
  policy      = data.aws_iam_policy_document.sdx_pushgateway_ecs_exec.json
}

data "aws_iam_policy_document" "sdx_pushgateway_ecs_exec" {
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
