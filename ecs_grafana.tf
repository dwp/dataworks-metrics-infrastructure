resource "aws_ecs_task_definition" "grafana" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_grafana_url}",
    "memory": ${var.fargate_memory},
    "name": "grafana",
    "networkMode": "awsvpc",
    "user": "0:0",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.monitoring.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "grafana"
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
        "name": "GRAFANA_CONFIG_S3_BUCKET",
        "value": "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id}"
      },
      {
        "name": "GRAFANA_CONFIG_S3_PREFIX",
        "value": "${var.name}/grafana"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "grafana" {
  count            = local.is_management_env ? 1 : 0
  name             = "grafana"
  cluster          = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.grafana[local.primary_role_index].arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.prometheus.id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana[local.primary_role_index].arn
    container_name   = "grafana"
    container_port   = 3000
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.grafana[local.primary_role_index].arn
    container_name = "grafana"
  }
}

resource "aws_service_discovery_service" "grafana" {
  count = local.is_management_env ? 1 : 0
  name  = "grafana"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "grafana" {
  name        = "prometheus"
  description = "Rules necesary for pulling container image and accessing other grafana instances"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "grafana" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_grafana_egress_https" {
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.secondary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.grafana.id
}

resource "aws_security_group_rule" "allow_egress_grafana_prom" {
  type              = "egress"
  to_port           = var.prom_port
  protocol          = "tcp"
  from_port         = var.prom_port
  security_group_id = aws_security_group.grafana.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ingress_grafana" {
  type              = "ingress"
  to_port           = 3000
  protocol          = "tcp"
  from_port         = 3000
  security_group_id = aws_security_group.grafana.id
  cidr_blocks       = ["0.0.0.0/0"]
}
