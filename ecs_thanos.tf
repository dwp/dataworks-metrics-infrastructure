resource "aws_ecs_task_definition" "thanos" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "thanos"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus[count.index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_prometheus_url}-temp:temp",
    "memory": ${var.fargate_memory},
    "name": "thanos",
    "networkMode": "awsvpc",
    "user": "0:0",
    "portMappings": [
      {
        "containerPort": 9090,
        "hostPort": 9090
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
      },
      {
        "name": "THANOS_ROLE",
        "value": "query"
      },
      {
        "name": "STORE_HOSTNAMES",
        "value": "${var.name}-${var.primary}.${local.environment}.services.${var.parent_domain_name}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "thanos" {
  count            = local.is_management_env ? 1 : 0
  name             = "thanos"
  cluster          = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.thanos[local.primary_role_index].arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.thanos[local.primary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.thanos[local.primary_role_index].arn
    container_name   = "thanos"
    container_port   = var.prom_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.thanos[local.primary_role_index].arn
    container_name = "thanos"
  }
}

resource "aws_service_discovery_service" "thanos" {
  count = local.is_management_env ? 1 : 0
  name  = "thanos"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "thanos" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos"
  description = "Rules necesary for pulling container image and allowing lb in"
  vpc_id      = module.vpc.outputs.vpcs[count.index].id
  tags        = merge(local.tags, { Name = "prometheus" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "thanos_query_allow_egress_https" {
  count             = local.is_management_env ? 1 : 0
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[count.index]]
  from_port         = 443
  security_group_id = aws_security_group.thanos[count.index].id
}

resource "aws_security_group_rule" "allow_ingress_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  type                     = "ingress"
  to_port                  = var.prom_port
  protocol                 = "tcp"
  from_port                = var.prom_port
  security_group_id        = aws_security_group.prometheus[count.index].id
  source_security_group_id = aws_security_group.thanos[local.primary_role_index].id
}
