resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  volume {
    name = "prometheus"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.prometheus.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.prometheus.id
      }
    }
  }

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_prometheus_url}",
    "memory": ${var.fargate_memory},
    "name": "prometheus",
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
        "awslogs-stream-prefix": "prometheus"
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
        "value": "${var.name}/prometheus"
      },
      {
        "name": "PROMETHEUS_ROLE",
        "value": "${local.roles[local.secondary_role_index]}"
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
  },
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_ecs_service_discovery_url}",
    "memory": ${var.fargate_memory},
    "name": "ecs-service-discovery",
    "networkMode": "awsvpc",
    "user": "nobody",
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
        "awslogs-stream-prefix": "ecs-service-discovery"
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
        "name": "SERVICE_DISCOVERY_DIRECTORY",
        "value": "/prometheus/ecs"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "prometheus" {
  name             = "prometheus"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.prometheus.arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.prometheus.id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.prometheus.arn
    container_name = "prometheus"
  }
}

resource "aws_cloudwatch_log_group" "monitoring" {
  name = "${data.terraform_remote_state.management.outputs.ecs_cluster_main_log_group.name}/${var.name}"
  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "monitoring" {
  name = "${local.environment}.services.${var.parent_domain_name}"
  vpc  = module.vpc.outputs.vpcs[0].id
}

resource "aws_service_discovery_service" "prometheus" {
  name = "${var.name}-${local.roles[local.secondary_role_index]}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "prometheus" {
  name        = "prometheus"
  description = "Rules necesary for pulling container image and accessing other prometheus instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "prometheus" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_prometheus_egress_https" {
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.secondary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_prometheus_egress_cloudwatch_exporter" {
  description              = "Allows prometheus to access exporter metrics"
  type                     = "egress"
  to_port                  = var.cloudwatch_exporter_port
  protocol                 = "tcp"
  from_port                = var.cloudwatch_exporter_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.cloudwatch_exporter.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_efs" {
  description              = "Allow prometheus to access efs mount target"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "egress"
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = aws_security_group.prometheus_efs.id
}

resource "aws_iam_role" "prometheus" {
  name               = "prometheus"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role.json
  tags               = merge(local.tags, { Name = "prometheus" })
}

data "aws_iam_policy_document" "prometheus_assume_role" {
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

resource "aws_iam_role_policy_attachment" "prometheus_read_config_attachment" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_read_config.arn
}

resource "aws_iam_policy" "prometheus_read_config" {
  name        = "PrometheusReadConfigPolicy"
  description = "Allow Prometheus to read from config bucket"
  policy      = data.aws_iam_policy_document.prometheus_read_config.json
}

data "aws_iam_policy_document" "prometheus_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/prometheus/*",
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

resource "aws_iam_role_policy_attachment" "prometheus_service_discovery_attachment" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_service_discovery.arn
}

resource "aws_iam_policy" "prometheus_service_discovery" {
  name        = "PrometheusServiceDiscoveryPolicy"
  description = "Allow Prometheus to perform service discovery"
  policy      = data.aws_iam_policy_document.prometheus_service_discovery.json
}

data "aws_iam_policy_document" "prometheus_service_discovery" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ecs:Describe*",
      "ecs:List*"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_efs_attachment" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_efs.arn
}

resource "aws_iam_policy" "prometheus_efs" {
  name        = "PrometheusEFSPolicy"
  description = "Allow Prometheus to access EFS volume"
  policy      = data.aws_iam_policy_document.prometheus_efs.json
}

data "aws_iam_policy_document" "prometheus_efs" {
  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.prometheus.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "prometheus_monitoring_bucket_read_write" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.monitoring_bucket_read_write.arn
}

resource "aws_iam_policy" "monitoring_bucket_read_write" {
  name        = "MonitoringBucketReadWritePolicy"
  description = "Allow Prometheus to read and write to monitoring bucket"
  policy      = data.aws_iam_policy_document.monitoring_bucket_read_write.json
}

data "aws_iam_policy_document" "monitoring_bucket_read_write" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject"
    ]

    resources = [
      "${local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.arn}",
      "${local.is_management_env ? aws_s3_bucket.monitoring[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [
      "${local.is_management_env ? aws_kms_key.monitoring_bucket_cmk[local.primary_role_index].arn : data.terraform_remote_state.management_dmi.outputs.monitoring_bucket.key}",
    ]
  }
}
