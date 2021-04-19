resource "aws_iam_role" "ucfs_pushgateway" {
  provider           = aws.ireland
  count              = local.is_management_env ? 0 : 1
  name               = "ucfs-claimant-pushgateway"
  assume_role_policy = data.aws_iam_policy_document.ucfs_claimant_pushgateway_assume_role.json
  tags               = merge(local.tags, { Name = "ucfs-claimant-pushgateway" })
}

data "aws_iam_policy_document" "ucfs_claimant_pushgateway_assume_role" {
  provider = aws.ireland

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

resource "aws_iam_role_policy_attachment" "ucfs_claimant_pushgateway_ecs_exec" {
  provider   = aws.ireland
  count      = local.is_management_env ? 0 : 1
  role       = aws_iam_role.ucfs_claimant_pushgateway[local.primary_role_index].name
  policy_arn = aws_iam_policy.ucfs_claimant_pushgateway_ecs_exec[local.primary_role_index].arn
}

resource "aws_iam_policy" "ucfs_claimant_pushgateway_ecs_exec" {
  provider    = aws.ireland
  count       = local.is_management_env ? 0 : 1
  name        = "UCFSClaimantPushgatewayECSExecPolicy"
  description = "Allow UCFSClaimantPushgateway container to exec from cli"
  policy      = data.aws_iam_policy_document.ucfs_claimant_pushgateway_ecs_exec.json
}

data "aws_iam_policy_document" "ucfs_claimant_pushgateway_ecs_exec" {
  provider = aws.ireland

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
