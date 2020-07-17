resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                   = "cloudwatch-exporter"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.cloudwatch_exporter.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_cloudwatch_exporter_url}",
    "memory": ${var.fargate_memory},
    "name": "cloudwatch-exporter",
    "networkMode": "awsvpc",
    "user": "nobody",
    "portMappings": [
      {
        "containerPort": ${var.cloudwatch_exporter_port},
        "hostPort": ${var.cloudwatch_exporter_port}
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.monitoring.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "cloudwatch-exporter"
      }
    },
    "placementStrategy": [
      {
        "field": "attribute:ecs.availability-zone",
        "type": "spread"
      }
    ],
    "environment": [
      {
        "name": "CLOUDWATCH_EXPORTER_CONFIG_S3_BUCKET",
        "value": "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id}"
      },
      {
        "name": "CLOUDWATCH_EXPORTER_CONFIG_S3_PREFIX",
        "value": "${var.name}/cloudwatch-exporter"
      },
      {
        "name": "PROMETHEUS",
        "value": "true"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name             = "cloudwatch-exporter"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.cloudwatch_exporter.arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.cloudwatch_exporter.id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.cloudwatch_exporter.arn
    container_name = "cloudwatch-exporter"
  }
}

resource "aws_service_discovery_service" "cloudwatch_exporter" {
  name = "cloudwatch-exporter"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "cloudwatch_exporter" {
  name        = "cloudwatch-exporter"
  description = "Rules necesary for pulling container image and accessing other thanos query instance"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "cloudwatch-exporter" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_cloudwatch_exporter_egress_https" {
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.secondary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.cloudwatch_exporter.id
}

resource "aws_iam_role" "cloudwatch_exporter" {
  name               = "cloudwatch-exporter"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_exporter_assume_role.json
  tags               = merge(local.tags, { Name = "cloudwatch-exporter" })
}

data "aws_iam_policy_document" "cloudwatch_exporter_assume_role" {
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

resource "aws_iam_role_policy_attachment" "cloudwatch_exporter_read_config_attachment" {
  role       = aws_iam_role.cloudwatch_exporter.name
  policy_arn = aws_iam_policy.cloudwatch_exporter_read_config.arn
}

resource "aws_iam_policy" "cloudwatch_exporter_read_config" {
  name        = "CloudwatchExporterReadConfigPolicy"
  description = "Allow Cloudwatch Exporter to read from config bucket"
  policy      = data.aws_iam_policy_document.cloudwatch_exporter_read_config.json
}

data "aws_iam_policy_document" "cloudwatch_exporter_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/cloudwatch-exporter/*",
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

resource "aws_iam_role_policy_attachment" "cloudwatch_exporter_read_cloudwatch_attachment" {
  role       = aws_iam_role.cloudwatch_exporter.name
  policy_arn = aws_iam_policy.cloudwatch_exporter_read_cloudwatch.arn
}

resource "aws_iam_policy" "cloudwatch_exporter_read_cloudwatch" {
  name        = "CloudwatchExporterReadCloudwatchPolicy"
  description = "Allow Cloudwatch Exporter to read from cloudwatch"
  policy      = data.aws_iam_policy_document.cloudwatch_exporter_read_cloudwatch.json
}

data "aws_iam_policy_document" "cloudwatch_exporter_read_cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:ListMetrics",
    ]

    resources = [
      "*",
    ]
  }
}
