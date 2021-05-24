resource "aws_iam_role" "cert_retriever" {
  name               = "cert_retriever"
  assume_role_policy = data.aws_iam_policy_document.cert_retriever_assume_role.json
  tags               = merge(local.tags, { Name = "cert_retriever" })
}

resource "aws_iam_instance_profile" "cert_retriever" {
  name = "cert_retriever-instance"
  role = aws_iam_role.cert_retriever.name
}

data "aws_iam_policy_document" "cert_retriever_assume_role" {
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

resource "aws_iam_role_policy_attachment" "cert_retriever_read_config_attachment" {
  role       = aws_iam_role.cert_retriever.name
  policy_arn = aws_iam_policy.cert_retriever_read_config.arn
}

resource "aws_iam_policy" "cert_retriever_read_config" {
  name        = "Cert_retrieverReadConfigPolicy"
  description = "Allow Cert_retriever to read from config bucket"
  policy      = data.aws_iam_policy_document.cert_retriever_read_config.json
}

data "aws_iam_policy_document" "cert_retriever_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/cert_retriever/*",
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

resource "aws_iam_role_policy_attachment" "cert_retriever_read_certs" {
  role       = aws_iam_role.cert_retriever.name
  policy_arn = aws_iam_policy.cert_retriever_read_certs.arn
}

resource "aws_iam_policy" "cert_retriever_read_certs" {
  name        = "Cert_retrieverReadCertsPolicy"
  description = "Allow Cert_retriever to read from ACM"
  policy      = data.aws_iam_policy_document.cert_retriever_read_certs.json
}

data "aws_iam_policy_document" "cert_retriever_read_certs" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "acm-pca:GetCertficate",
    ]

    resources = [
      "arn:aws:acm:${var.region}:${local.account[local.environment]}:certificate/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cert_retriever_service_discovery_attachment" {
  role       = aws_iam_role.cert_retriever.name
  policy_arn = aws_iam_policy.cert_retriever_service_discovery.arn
}

resource "aws_iam_policy" "cert_retriever_service_discovery" {
  name        = "Cert_retrieverServiceDiscoveryPolicy"
  description = "Allow Cert_retriever to perform service discovery"
  policy      = data.aws_iam_policy_document.cert_retriever_service_discovery.json
}

data "aws_iam_policy_document" "cert_retriever_service_discovery" {
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


resource "aws_iam_role_policy_attachment" "cert_retriever_ecs_exec" {
  role       = aws_iam_role.cert_retriever.name
  policy_arn = aws_iam_policy.cert_retriever_ecs_exec.arn
}

resource "aws_iam_policy" "cert_retriever_ecs_exec" {
  name        = "Cert_retrieverECSExecPolicy"
  description = "Allow Cert_retriever container to exec from cli"
  policy      = data.aws_iam_policy_document.cert_retriever_ecs_exec.json
}

data "aws_iam_policy_document" "cert_retriever_ecs_exec" {
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
