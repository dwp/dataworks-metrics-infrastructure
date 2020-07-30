resource "aws_iam_role" "adg_pushgateway" {
  count              = local.is_management_env ? 0 : 1
  name               = "adg-pushgateway"
  assume_role_policy = data.aws_iam_policy_document.adg_pushgateway_assume_role.json
  tags               = merge(local.tags, { Name = "adg-pushgateway" })
}

data "aws_iam_policy_document" "adg_pushgateway_assume_role" {
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

