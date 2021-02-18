resource "aws_iam_role" "ingest_pushgateway" {
  count              = local.is_management_env ? 0 : 1
  name               = "ingest-pushgateway"
  assume_role_policy = data.aws_iam_policy_document.ingest_pushgateway_assume_role.json
  tags               = merge(local.tags, { Name = "ingest-pushgateway" })
}

data "aws_iam_policy_document" "ingest_pushgateway_assume_role" {
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

