resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.role}-${var.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus.arn
  execution_role_arn       = var.mgmt.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${var.mgmt.ecr_prometheus_url}:slave",
    "memory": ${var.fargate_memory},
    "name": "${var.role}-${var.name}",
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
        "awslogs-group": "${var.mgmt.ecs_cluster_main_log_group.name}",
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
        "value": "${var.mgmt.config_bucket.id}"
      },
      {
        "name": "PROMETHEUS_CONFIG_S3_PREFIX",
        "value": "${var.s3_prefix}"
      },
      {
        "name": "PROMETHEUS_ROLE",
        "value": "${var.role}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "prometheus" {
  name            = "${var.role}-${var.name}"
  cluster         = var.mgmt.ecs_cluster_main.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.web.id]
    subnets         = var.vpc.aws_subnets_private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_http.arn
    container_name   = "${var.role}-${var.name}"
    container_port   = var.prom_port
  }
}

data template_file "prometheus_config" {
  template = file("${path.module}/config/prometheus-${var.role}.tpl")
}

resource "aws_s3_bucket_object" "prometheus_config" {
  bucket     = var.mgmt.config_bucket.id
  key        = "${var.s3_prefix}/prometheus-${var.role}.yml"
  content    = data.template_file.prometheus_config.rendered
  kms_key_id = var.mgmt.config_bucket.cmk_arn
}
