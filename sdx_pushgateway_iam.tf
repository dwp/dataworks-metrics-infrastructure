resource "aws_iam_role" "sdx_pushgateway" {
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
