resource "aws_ecs_task_definition" "grafana" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.grafana[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_grafana_url}",
    "memory": ${var.fargate_memory},
    "name": "grafana",
    "networkMode": "awsvpc",
    "user": "grafana",
    "portMappings": [
      {
        "containerPort": ${var.grafana_port},
        "hostPort": ${var.grafana_port}
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
      },
      {
        "name": "HTTP_PROXY",
        "value": "http://${aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name}:3128"
      },
      {
        "name": "HTTPS_PROXY",
        "value": "http://${aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name}:3128"
      },
      {
        "name": "NO_PROXY",
        "value": "127.0.0.1,s3.${var.region}.amazonaws.com"
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
    security_groups = [aws_security_group.grafana[0].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana[local.primary_role_index].arn
    container_name   = "grafana"
    container_port   = var.grafana_port
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
  count       = local.is_management_env ? 1 : 0
  name        = "grafana"
  description = "Rules necesary for pulling container image and accessing other grafana instances"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "grafana" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_grafana_egress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.primary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.grafana[0].id
}

resource "aws_security_group_rule" "allow_egress_grafana_thanos_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow grafana to access thanos query api"
  type                     = "egress"
  to_port                  = var.thanos_port_http
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  security_group_id        = aws_security_group.grafana[0].id
  source_security_group_id = aws_security_group.thanos[0].id
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_grafana_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access grafanas user interface"
  type                     = "ingress"
  to_port                  = var.grafana_port
  protocol                 = "tcp"
  from_port                = var.grafana_port
  security_group_id        = aws_security_group.grafana[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}

resource "aws_iam_role" "grafana" {
  count              = local.is_management_env ? 1 : 0
  name               = "grafana"
  assume_role_policy = data.aws_iam_policy_document.grafana.json
  tags               = merge(local.tags, { Name = "grafana" })
}

data "aws_iam_policy_document" "grafana" {
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

resource "aws_iam_role_policy" "grafana" {
  count  = local.is_management_env ? 1 : 0
  policy = data.aws_iam_policy_document.grafana_read_config.json
  role   = aws_iam_role.grafana[local.primary_role_index].id
}

data "aws_iam_policy_document" "grafana_read_config" {
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
      "${local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.arn : data.terraform_remote_state.common.outputs.config_bucket.arn}/${var.name}/grafana/*",
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
