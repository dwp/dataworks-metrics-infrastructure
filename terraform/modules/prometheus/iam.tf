resource "aws_iam_role" "prometheus" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.prometheus.json
  tags               = var.tags
}

data "aws_iam_policy_document" "prometheus" {
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
