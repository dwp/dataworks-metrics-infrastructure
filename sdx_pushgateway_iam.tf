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
