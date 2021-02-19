resource "aws_iam_role" "htme_pushgateway" {
  count              = local.is_management_env ? 0 : 1
  name               = "htme-pushgateway"
  assume_role_policy = data.aws_iam_policy_document.htme_pushgateway_assume_role.json
  tags               = merge(local.tags, { Name = "htme-pushgateway" })
}

data "aws_iam_policy_document" "htme_pushgateway_assume_role" {
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

