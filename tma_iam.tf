resource "aws_iam_role" "tma" {
  name               = "tma"
  assume_role_policy = data.aws_iam_policy_document.tma_assume_role.json
  tags               = merge(local.tags, { Name = "tma" })
}

resource "aws_iam_instance_profile" "tma" {
  name = "tma-instance"
  role = aws_iam_role.tma.name
}

data "aws_iam_policy_document" "tma_assume_role" {
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

resource "aws_iam_role_policy_attachment" "tma_read_config_attachment" {
  role       = aws_iam_role.tma.name
  policy_arn = aws_iam_policy.tma_read_config.arn
}

resource "aws_iam_policy" "tma_read_config" {
  name        = "tmaReadConfigPolicy"
  description = "Allow tma to read from config bucket"
  policy      = data.aws_iam_policy_document.tma_read_config.json
}

data "aws_iam_policy_document" "tma_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]
    resources = [
      local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn,
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
      local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.cmk_arn : data.terraform_remote_state.common.outputs.config_bucket_cmk.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "tma_service_discovery_attachment" {
  role       = aws_iam_role.tma.name
  policy_arn = aws_iam_policy.tma_service_discovery.arn
}

resource "aws_iam_policy" "tma_service_discovery" {
  name        = "tmaServiceDiscoveryPolicy"
  description = "Allow tma to perform service discovery"
  policy      = data.aws_iam_policy_document.tma_service_discovery.json
}

data "aws_iam_policy_document" "tma_service_discovery" {
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


resource "aws_iam_role_policy_attachment" "tma_ecs_exec" {
  role       = aws_iam_role.tma.name
  policy_arn = aws_iam_policy.tma_ecs_exec.arn
}

resource "aws_iam_policy" "tma_ecs_exec" {
  name        = "tmaECSExecPolicy"
  description = "Allow tma container to exec from cli"
  policy      = data.aws_iam_policy_document.tma_ecs_exec.json
}

data "aws_iam_policy_document" "tma_ecs_exec" {
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
