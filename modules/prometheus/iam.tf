resource "aws_iam_role" "prometheus" {
  name               = "${var.role}-${var.name}"
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

data "aws_iam_policy_document" "prometheus_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      var.mgmt.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${var.mgmt.config_bucket.arn}/${var.s3_prefix}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      var.mgmt.config_bucket.cmk_arn,
    ]
  }
}

resource "aws_iam_role_policy" "prometheus" {
  policy = data.aws_iam_policy_document.prometheus_read_config.json
  role   = aws_iam_role.prometheus.id
}
