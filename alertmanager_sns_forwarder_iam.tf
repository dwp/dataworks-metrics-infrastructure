resource "aws_iam_role" "alertmanager_sns_forwarder" {
  count              = local.is_management_env ? 1 : 0
  name               = "alertmanager-sns-forwarder"
  assume_role_policy = data.aws_iam_policy_document.alertmanager_sns_forwarder_assume_role.json
  tags               = merge(local.tags, { Name = "alertmanager-sns-forwarder" })
}

data "aws_iam_policy_document" "alertmanager_sns_forwarder_assume_role" {
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

resource "aws_iam_role_policy_attachment" "alertmanager_sns_forwarder_ecs_exec" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.alertmanager_sns_forwarder[local.primary_role_index].name
  policy_arn = aws_iam_policy.alertmanager_sns_forwarder_ecs_exec[local.primary_role_index].arn
}

resource "aws_iam_policy" "alertmanager_sns_forwarder_ecs_exec" {
  count       = local.is_management_env ? 1 : 0
  name        = "alertmanagerSNSForwarderECSExecPolicy"
  description = "Allow alertmanagerSNSForwarder container to exec from cli"
  policy      = data.aws_iam_policy_document.alertmanager_sns_forwarder_ecs_exec.json
}

data "aws_iam_policy_document" "alertmanager_sns_forwarder_ecs_exec" {
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

  statement {
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.test_forwarder_topic.arn
    ]
  }
}
