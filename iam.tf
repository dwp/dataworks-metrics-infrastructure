resource "aws_iam_role" "prometheus" {
  count              = length(local.roles)
  name               = "${local.roles[count.index]}-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.prometheus.json
  tags               = merge(local.tags, { Name = "prometheus" })
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

data "aws_iam_policy_document" "prometheus_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${local.roles[0] == "master" ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${local.roles[0] == "master" ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.s3_prefix}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "${local.roles[0] == "master" ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeTags",
      "ec2:DescribeSnapshots"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "prometheus" {
  count  = length(local.roles)
  policy = data.aws_iam_policy_document.prometheus_read_config.json
  role   = aws_iam_role.prometheus[count.index].id
}
