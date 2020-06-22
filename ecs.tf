resource "aws_ecs_task_definition" "prometheus" {
  count              = length(local.roles)
  family             = "prometheus-${local.roles[count.index]}"
  network_mode       = "awsvpc"
  cpu                = "512"
  memory             = "4096"
  task_role_arn      = aws_iam_role.prometheus[count.index].arn
  execution_role_arn = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  volume {
    name = "prometheus-${local.roles[count.index]}"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.prometheus[count.index].id
      root_directory = "/"
    }
  }

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_prometheus_url}:slave",
    "memory": ${var.fargate_memory},
    "name": "prometheus-${local.roles[count.index]}",
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
        "sourceVolume": "prometheus-${local.roles[count.index]}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${data.terraform_remote_state.management.outputs.ecs_cluster_main_log_group.name}",
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
        "value": "${local.roles[count.index]}"
      }
    ]
  },
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_thanos_url}",
    "memory": ${var.fargate_memory},
    "name": "thanos-${local.roles[count.index]}",
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
        "sourceVolume": "prometheus-${local.roles[count.index]}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${data.terraform_remote_state.management.outputs.ecs_cluster_main_log_group.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "thanos"
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

resource "aws_ecs_service" "prometheus_primary" {
  count            = local.is_management_env ? 1 : 0
  name             = "prometheus-${var.primary}"
  cluster          = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.prometheus[local.primary_role_index].arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.prometheus[local.primary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus[local.primary_role_index].arn
    container_name   = "thanos-${var.primary}"
    container_port   = 10902
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.prometheus[local.primary_role_index].arn
    container_name = "prometheus-${var.primary}"
  }
}

resource "aws_ecs_service" "prometheus_secondary" {
  name             = "prometheus-${var.secondary}"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.prometheus[local.secondary_role_index].arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.prometheus[local.secondary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.prometheus[local.secondary_role_index].arn
    container_name = "prometheus-${var.secondary}"
  }
}

resource "aws_service_discovery_private_dns_namespace" "monitoring" {
  name = "${local.environment}.services.${var.parent_domain_name}"
  vpc  = module.vpc.outputs.vpcs[0].id
}

resource "aws_service_discovery_service" "prometheus" {
  count = length(local.roles)
  name  = "${var.name}-${local.roles[count.index]}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "prometheus" {
  count       = length(local.roles)
  name        = "${var.name}-${local.roles[count.index]}"
  description = "Rules necesary for pulling container image and accessing other prometheus instances"
  vpc_id      = module.vpc.outputs.vpcs[count.index].id
  tags        = merge(local.tags, { Name = "prometheus" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress_https" {
  count             = length(local.roles)
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[count.index]]
  from_port         = 443
  security_group_id = aws_security_group.prometheus[count.index].id
}

resource "aws_security_group_rule" "prometheus_allow_egress_efs" {
  count                    = length(local.roles)
  description              = "Allow prometheus to access efs"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus[count.index].id
  to_port                  = 2049
  type                     = "egress"
  source_security_group_id = aws_security_group.efs[count.index].id
}

resource "aws_security_group_rule" "allow_ingress_prom" {
  count             = length(local.roles)
  type              = "ingress"
  to_port           = var.prom_port
  protocol          = "tcp"
  from_port         = var.prom_port
  security_group_id = aws_security_group.prometheus[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ingress_thanos_http" {
  count             = length(local.roles)
  type              = "ingress"
  to_port           = 10902
  protocol          = "tcp"
  from_port         = 10902
  security_group_id = aws_security_group.prometheus[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ingress_thanos_grpc" {
  count             = length(local.roles)
  type              = "ingress"
  to_port           = 10901
  protocol          = "tcp"
  from_port         = 10901
  security_group_id = aws_security_group.prometheus[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}
