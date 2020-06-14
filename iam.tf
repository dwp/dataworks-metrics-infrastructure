resource "aws_iam_role" "prometheus" {
  count              = length(lookup(local.roles, local.environment))
  name               = "${lookup(local.roles, local.environment)[count.index]}-${var.name}"
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
      data.terraform_remote_state.management.outputs.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${data.terraform_remote_state.management.outputs.config_bucket.arn}/${var.s3_prefix}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      data.terraform_remote_state.management.outputs.config_bucket.cmk_arn,
    ]
  }
}

resource "aws_iam_role_policy" "prometheus" {
  count  = length(lookup(local.roles, local.environment))
  policy = data.aws_iam_policy_document.prometheus_read_config.json
  role   = aws_iam_role.prometheus[count.index].id
}
