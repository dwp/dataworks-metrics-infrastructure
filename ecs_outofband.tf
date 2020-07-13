resource "aws_ecs_task_definition" "outofband" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "outofband"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.outofband[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  volume {
    name = "outofband"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.outofband[local.primary_role_index].id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.outofband[local.primary_role_index].id
      }
    }
  }

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_prometheus_url}",
    "memory": ${var.fargate_memory},
    "name": "outofband",
    "networkMode": "awsvpc",
    "user": "nobody",
    "portMappings": [
      {
        "containerPort": ${var.prometheus_port},
        "hostPort": ${var.prometheus_port}
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/prometheus",
        "sourceVolume": "prometheus"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.monitoring.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "outofband"
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
        "name": "PROMETHEUS_CONFIG_S3_BUCKET",
        "value": "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id}"
      },
      {
        "name": "PROMETHEUS_CONFIG_S3_PREFIX",
        "value": "${var.name}/outofband"
      },
      {
        "name": "PROMETHEUS_ROLE",
        "value": "outofband"
      }
    ]
  },
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_thanos_url}",
    "memory": ${var.fargate_memory},
    "name": "thanos-sidecar",
    "networkMode": "awsvpc",
    "user": "nobody",
    "portMappings": [
      {
        "containerPort": 10901,
        "hostPort": 10901
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/prometheus",
        "sourceVolume": "prometheus"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.monitoring.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "thanos-sidecar"
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
        "name": "THANOS_CONFIG_S3_BUCKET",
        "value": "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id}"
      },
      {
        "name": "THANOS_CONFIG_S3_PREFIX",
        "value": "${var.name}/thanos"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "outofband" {
  count            = local.is_management_env ? 1 : 0
  name             = "outofband"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.outofband[local.primary_role_index].arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.outofband[local.primary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.outofband[local.primary_role_index].arn
    container_name = "outofband"
  }
}

resource "aws_service_discovery_service" "outofband" {
  count = local.is_management_env ? 1 : 0
  name  = "outofband"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "outofband" {
  count       = local.is_management_env ? 1 : 0
  name        = "outofband"
  description = "Rules necesary for pulling container image and accessing other thanos ruler instance"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "outofband" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_outofband_egress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.secondary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.outofband[local.primary_role_index].id
}

resource "aws_security_group_rule" "outofband_allow_egress_efs" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow outofband to access efs mount target"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "egress"
  security_group_id        = aws_security_group.outofband[local.primary_role_index].id
  source_security_group_id = aws_security_group.outofband_efs[local.primary_role_index].id
}

resource "aws_security_group_rule" "outofband_allow_egress_thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow outofband to access thanos ruler"
  from_port                = var.thanos_port_http
  protocol                 = "tcp"
  to_port                  = var.thanos_port_http
  type                     = "egress"
  security_group_id        = aws_security_group.outofband[local.primary_role_index].id
  source_security_group_id = aws_security_group.thanos_ruler[0].id
}

resource "aws_iam_role" "outofband" {
  count              = local.is_management_env ? 1 : 0
  name               = "outofband"
  assume_role_policy = data.aws_iam_policy_document.outofband_assume_role.json
  tags               = merge(local.tags, { Name = "outofband" })
}

data "aws_iam_policy_document" "outofband_assume_role" {
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

resource "aws_iam_role_policy_attachment" "outofband_read_config_attachment" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.outofband[local.primary_role_index].name
  policy_arn = aws_iam_policy.outofband_read_config[local.primary_role_index].arn
}

resource "aws_iam_policy" "outofband_read_config" {
  count       = local.is_management_env ? 1 : 0
  name        = "OutofbandReadConfigPolicy"
  description = "Allow Outofband to read from config bucket"
  policy      = data.aws_iam_policy_document.outofband_read_config.json
}

data "aws_iam_policy_document" "outofband_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/thanos/*",
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/prometheus/*",
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

resource "aws_iam_role_policy_attachment" "outofband_efs_attachment" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.outofband[local.primary_role_index].name
  policy_arn = aws_iam_policy.outofband_efs[local.primary_role_index].arn
}

resource "aws_iam_policy" "outofband_efs" {
  count       = local.is_management_env ? 1 : 0
  name        = "OutofbandEFSPolicy"
  description = "Allow Prometheus to access EFS volume"
  policy      = data.aws_iam_policy_document.outofband_efs.json
}

data "aws_iam_policy_document" "outofband_efs" {
  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.outofband[local.primary_role_index].arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "outofband_monitoring_bucket_read_write" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.outofband[local.primary_role_index].name
  policy_arn = aws_iam_policy.monitoring_bucket_read_write.arn
}

