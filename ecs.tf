resource "aws_ecs_task_definition" "prometheus" {
  count                    = length(lookup(local.roles, local.environment))
  family                   = "${lookup(local.roles, local.environment)[count.index]}-${var.name}"
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
    "name": "${lookup(local.roles, local.environment)[count.index]}-${var.name}",
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
        "value": "${lookup(local.roles, local.environment)[count.index]}"
      },
      {
        "name": "TEMP",
        "value": "${lookup(local.roles, local.environment)[count.index]}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "prometheus" {
  count           = length(lookup(local.roles, local.environment))
  name            = "${lookup(local.roles, local.environment)[count.index]}-${var.name}"
  cluster         = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition = aws_ecs_task_definition.prometheus[count.index].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.web[count.index].id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_http[count.index].arn
    container_name   = "${lookup(local.roles, local.environment)[count.index]}-${var.name}"
    container_port   = var.prom_port
  }
}

data template_file "prometheus_config" {
  count    = length(lookup(local.roles, local.environment))
  template = file("${path.module}/config/prometheus-${lookup(local.roles, local.environment)[count.index]}.tpl")
}

resource "aws_s3_bucket_object" "prometheus_config" {
  count      = length(lookup(local.roles, local.environment))
  bucket     = data.terraform_remote_state.management.outputs.config_bucket.id
  key        = "${var.s3_prefix}/prometheus-${lookup(local.roles, local.environment)[count.index]}.yml"
  content    = data.template_file.prometheus_config[count.index].rendered
  kms_key_id = data.terraform_remote_state.management.outputs.config_bucket.cmk_arn
}

resource "aws_lb_target_group" "web_http" {
  count       = length(lookup(local.roles, local.environment))
  name        = "${lookup(local.roles, local.environment)[count.index]}-${var.name}-http"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc.id
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
  count        = length(lookup(local.roles, local.environment))
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_http[count.index].arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.prometheus.fqdn]
  }
}

resource "aws_security_group" "web" {
  count       = length(lookup(local.roles, local.environment))
  name        = "${lookup(local.roles, local.environment)[count.index]}-${var.name}"
  description = "prometheus web access"
  vpc_id      = module.vpc.vpc.id
  tags        = merge(local.tags, { Name = "prometheus" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress_https" {
  count             = length(lookup(local.roles, local.environment))
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.s3_prefix_list_id]
  from_port         = 443
  security_group_id = aws_security_group.web[count.index].id
}

resource "aws_security_group_rule" "allow_ingress_prom" {
  count             = length(lookup(local.roles, local.environment))
  type              = "ingress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.web[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_egress_prometheus" {
  count             = length(lookup(local.roles, local.environment))
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.web[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role" "prometheus" {
  count              = length(lookup(local.roles, local.environment))
  name               = "${lookup(local.roles, local.environment)[count.index]}-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.prometheus.json
  tags               = merge(local.tags, { Name = "prometheus" })
}

data "aws_iam_policy_document" "prometheus" {
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

data "aws_iam_policy_document" "prometheus_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      data.terraform_remote_state.management.outputs.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${data.terraform_remote_state.management.outputs.config_bucket.arn}/${var.s3_prefix}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      data.terraform_remote_state.management.outputs.config_bucket.cmk_arn,
    ]
  }
}

resource "aws_iam_role_policy" "prometheus" {
  count  = length(lookup(local.roles, local.environment))
  policy = data.aws_iam_policy_document.prometheus_read_config.json
  role   = aws_iam_role.prometheus[count.index].id
}
