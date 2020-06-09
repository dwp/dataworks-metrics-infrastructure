resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.role}-${var.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus.arn
  execution_role_arn       = var.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.aws_ecr_repository.prometheus.repository_url}:slave",
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
        "awslogs-group": "${var.ecs_cluster_main_log_group.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "prometheus"
      }
    },
    "placementStrategy": [
      {
        "field": "attribute:ecs.availability-zone",
        "type": "spread"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "prometheus" {
  name            = "${var.role}-${var.name}"
  cluster         = var.ecs_cluster_main.id
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
