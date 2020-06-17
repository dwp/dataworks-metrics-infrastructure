resource "aws_ecs_task_definition" "prometheus" {
  count                    = length(local.roles)
  family                   = "${local.roles[count.index]}-${var.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus[count.index].arn
  execution_role_arn       = data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.terraform_remote_state.management.outputs.ecr_prometheus_url}:slave",
    "memory": ${var.fargate_memory},
    "name": "${local.roles[count.index]}-${var.name}",
    "networkMode": "awsvpc",
    "user" : "nobody",
    "portMappings": [
      {
        "containerPort": ${var.prom_port},
        "hostPort": ${var.prom_port}
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
        "value": "${data.terraform_remote_state.management.outputs.config_bucket.id}"
      },
      {
        "name": "PROMETHEUS_CONFIG_S3_PREFIX",
        "value": "${var.s3_prefix}"
      },
      {
        "name": "PROMETHEUS_ROLE",
        "value": "${local.roles[count.index]}"
      },
      {
        "name": "TEMP",
        "value": "${local.roles[count.index]}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "prometheus" {
  count           = length(local.roles)
  name            = "${local.roles[count.index]}-${var.name}"
  cluster         = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition = aws_ecs_task_definition.prometheus[count.index].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.web[count.index].id]
    subnets         = module.vpc.outputs.private_subnets[count.index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_http[count.index].arn
    container_name   = "${local.roles[count.index]}-${var.name}"
    container_port   = var.prom_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.prometheus[count.index].arn
    container_name = "${var.name}-${local.roles[count.index]}"
  }
}

data template_file "prometheus_config" {
  count    = length(local.roles)
  template = file("${path.module}/config/prometheus-${local.roles[count.index]}.tpl")
  vars = {
    parent_domain_name = var.parent_domain_name
  }
}

resource "aws_s3_bucket_object" "prometheus_config" {
  count      = length(local.roles)
  bucket     = data.terraform_remote_state.management.outputs.config_bucket.id
  key        = "${var.s3_prefix}/prometheus-${local.roles[count.index]}.yml"
  content    = data.template_file.prometheus_config[count.index].rendered
  kms_key_id = data.terraform_remote_state.management.outputs.config_bucket.cmk_arn
}

resource "aws_service_discovery_private_dns_namespace" "prometheus" {
  name = "services.${var.parent_domain_name}"
  vpc  = module.vpc.outputs.vpc_ids[0]
}

resource "aws_service_discovery_service" "prometheus" {
  count = length(local.roles)
  name  = "${var.name}-${local.roles[count.index]}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.prometheus.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_lb_target_group" "web_http" {
  count       = length(local.roles)
  name        = "${local.roles[count.index]}-${var.name}-http"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = module.vpc.outputs.vpc_ids[count.index]
  target_type = "ip"

  health_check {
    port    = "9090"
    path    = "/-/healthy"
    matcher = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge(local.tags, { Name = "prometheus" })
}

resource "aws_lb_listener_rule" "https" {
  count        = length(local.roles)
  listener_arn = aws_lb_listener.https[count.index].arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_http[count.index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.prometheus[count.index].fqdn]
  }
}

resource "aws_security_group" "web" {
  count       = length(local.roles)
  name        = "${local.roles[count.index]}-${var.name}"
  description = "prometheus web access"
  vpc_id      = module.vpc.outputs.vpc_ids[count.index]
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
  security_group_id = aws_security_group.web[count.index].id
}

resource "aws_security_group_rule" "allow_ingress_prom" {
  count             = length(local.roles)
  type              = "ingress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.web[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}
