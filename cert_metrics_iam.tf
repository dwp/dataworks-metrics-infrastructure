resource "aws_iam_role" "cert_metrics" {
  name               = "cert_metrics"
  assume_role_policy = data.aws_iam_policy_document.cert_metrics_assume_role.json
  tags               = merge(local.tags, { Name = "cert_metrics" })
}

resource "aws_iam_instance_profile" "cert_metrics" {
  name = "cert_metrics-instance"
  role = aws_iam_role.cert_metrics.name
}

data "aws_iam_policy_document" "cert_metrics_assume_role" {
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

resource "aws_iam_role_policy_attachment" "cert_metrics_read_config_attachment" {
  role       = aws_iam_role.cert_metrics.name
  policy_arn = aws_iam_policy.cert_metrics_read_config.arn
}

resource "aws_iam_policy" "cert_metrics_read_config" {
  name        = "cert_metricsReadConfigPolicy"
  description = "Allow cert_metrics to read from config bucket"
  policy      = data.aws_iam_policy_document.cert_metrics_read_config.json
}

data "aws_iam_policy_document" "cert_metrics_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/thanos/*",
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/cert_metrics/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn}",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cert_metrics_read_certs" {
  role       = aws_iam_role.cert_metrics.name
  policy_arn = aws_iam_policy.cert_metrics_read_certs.arn
}

resource "aws_iam_policy" "cert_metrics_read_certs" {
  name        = "cert_metricsReadCertsPolicy"
  description = "Allow cert_metrics to read from ACM"
  policy      = data.aws_iam_policy_document.cert_metrics_read_certs.json
}

data "aws_iam_policy_document" "cert_metrics_read_certs" {

  statement {
    effect = "Allow"

    actions = [
      "acm-pca:ListCertificate*",
      "acm:ListCertificates",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "acm-pca:GetCertificate",
      "acm:GetCertificate",
    ]

    resources = [
      "arn:aws:acm:${var.region}:${local.account[local.environment]}:certificate/*",
      "arn:aws:acm-pca:${var.region}:${local.account[local.environment]}:certificate-authority/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cert_metrics_service_discovery_attachment" {
  role       = aws_iam_role.cert_metrics.name
  policy_arn = aws_iam_policy.cert_metrics_service_discovery.arn
}

resource "aws_iam_policy" "cert_metrics_service_discovery" {
  name        = "cert_metricsServiceDiscoveryPolicy"
  description = "Allow cert_metrics to perform service discovery"
  policy      = data.aws_iam_policy_document.cert_metrics_service_discovery.json
}

data "aws_iam_policy_document" "cert_metrics_service_discovery" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:Describe*",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:CreateTags",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolumeAttribute"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:Describe*",
      "ecs:List*",
    ]

    resources = [
      "*"
    ]
  }
}


resource "aws_iam_role_policy_attachment" "cert_metrics_ecs_exec" {
  role       = aws_iam_role.cert_metrics.name
  policy_arn = aws_iam_policy.cert_metrics_ecs_exec.arn
}

resource "aws_iam_policy" "cert_metrics_ecs_exec" {
  name        = "cert_metricsECSExecPolicy"
  description = "Allow cert_metrics container to exec from cli"
  policy      = data.aws_iam_policy_document.cert_metrics_ecs_exec.json
}

data "aws_iam_policy_document" "cert_metrics_ecs_exec" {
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

resource "aws_iam_role" "execute_ecs_task" {
  name               = "cert_metrics_scheduler"
  assume_role_policy = data.aws_iam_policy_document.cert_metrics_assume_role.json
  tags               = merge(local.tags, { Name = "cert_metrics" })
}


resource "aws_iam_role_policy_attachment" "execute_ecs_task" {
  role       = aws_iam_role.execute_ecs_task.name
  policy_arn = aws_iam_policy.execute_ecs_task.arn
}

resource "aws_iam_policy" "execute_ecs_task" {
  name        = "ExecuteEcsTasks"
  description = "Allow cloudwatch event to execute ecs tasks"
  policy      = data.aws_iam_policy_document.execute_ecs_task.json
}

data "aws_iam_policy_document" "execute_ecs_task" {

  statement {
    effect = "Allow"

    actions = [
      "ecs:RunTask",
    ]

    resources = [
      aws_ecs_task_definition.cert_metrics.container_definitions[0].arn,
    ]
  }
}
