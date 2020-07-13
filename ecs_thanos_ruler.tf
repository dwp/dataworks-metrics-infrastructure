resource "aws_ecs_task_definition" "thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "thanos-ruler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.thanos_ruler[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_thanos_url}",
    "memory": ${var.fargate_memory},
    "name": "thanos-ruler",
    "networkMode": "awsvpc",
    "user": "nobody",
    "portMappings": [
      {
        "containerPort": ${var.thanos_port_http},
        "hostPort": ${var.thanos_port_http}
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.monitoring.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "thanos-ruler"
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
        "name": "THANOS_MODE",
        "value": "rule"
      },
      {
        "name": "QUERY_URL",
        "value": "thanos-query.${local.environment}.services.${var.parent_domain_name}:${var.thanos_port_http}"
      },
      {
        "name": "ALERTMANAGER_URL",
        "value": "alertmanager.${local.environment}.services.${var.parent_domain_name}:${var.alertmanager_port}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "thanos_ruler" {
  count            = local.is_management_env ? 1 : 0
  name             = "thanos-ruler"
  cluster          = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.thanos_ruler[local.primary_role_index].arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.thanos_ruler[0].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.thanos_ruler[local.primary_role_index].arn
    container_name   = "thanos-ruler"
    container_port   = var.prometheus_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.thanos_ruler[local.primary_role_index].arn
    container_name = "thanos-ruler"
  }
}

resource "aws_service_discovery_service" "thanos_ruler" {
  count = local.is_management_env ? 1 : 0
  name  = "thanos-ruler"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_security_group" "thanos_ruler" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-ruler"
  description = "Rules necesary for pulling container image and accessing other thanos instances"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "thanos-ruler" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_thanos_ruler_egress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.primary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.thanos_ruler[0].id
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_thanos_ruler_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access thanos user interface"
  type                     = "ingress"
  to_port                  = var.thanos_port_http
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_egress_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access thanos query"
  type                     = "egress"
  to_port                  = var.thanos_port_http
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.thanos_query[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_egress_alertmanager" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access alertmanager"
  type                     = "egress"
  to_port                  = var.alertmanager_port
  protocol                 = "tcp"
  from_port                = var.alertmanager_port
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.alertmanager[0].id
}

resource "aws_security_group_rule" "allow_outofband_ingress_thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows outofband to access thanos ruler"
  type                     = "ingress"
  to_port                  = var.prometheus_port
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.outofband[0].id
}

resource "aws_iam_role" "thanos_ruler" {
  count              = local.is_management_env ? 1 : 0
  name               = "thanos-ruler"
  assume_role_policy = data.aws_iam_policy_document.thanos_ruler_assume_role.json
  tags               = merge(local.tags, { Name = "thanos-ruler" })
}

data "aws_iam_policy_document" "thanos_ruler_assume_role" {
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

resource "aws_iam_role_policy_attachment" "thanos_ruler_read_config_attachment" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.thanos_ruler[local.primary_role_index].name
  policy_arn = aws_iam_policy.thanos_ruler_read_config[local.primary_role_index].arn
}

resource "aws_iam_policy" "thanos_ruler_read_config" {
  count       = local.is_management_env ? 1 : 0
  name        = "ThanosrulerReadConfigPolicy"
  description = "Allow Thanos to read from config bucket"
  policy      = data.aws_iam_policy_document.thanos_ruler_read_config.json
}

data "aws_iam_policy_document" "thanos_ruler_read_config" {
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

resource "aws_iam_role_policy_attachment" "thanos_ruler_monitoring_bucket_read_write" {
  count      = local.is_management_env ? 1 : 0
  role       = aws_iam_role.thanos_ruler[0].name
  policy_arn = aws_iam_policy.monitoring_bucket_read_write.arn
}
