resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  volume {
    name = "prometheus"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.prometheus.id
      root_directory = "/"
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
    "user": "0:0",
    "portMappings": [
      {
        "containerPort": ${var.prom_port},
        "hostPort": ${var.prom_port}
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
    "user": "0:0",
    "portMappings": [
      {
        "containerPort": 10901,
        "hostPort": 10901
      },
      {
        "containerPort": 10902,
        "hostPort": 10902
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
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.secondary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "allow_ingress_prom" {
  type              = "ingress"
  to_port           = var.prom_port
  protocol          = "tcp"
  from_port         = var.prom_port
  security_group_id = aws_security_group.prometheus.id
  cidr_blocks       = ["0.0.0.0/0"]
}
