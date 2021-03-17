resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                   = "cloudwatch-exporter"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.cloudwatch_exporter.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.cloudwatch_exporter_definition.rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "cloudwatch_exporter_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "cloudwatch-exporter"
    group_name    = "cloudwatch_exporter"
    cpu           = var.fargate_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_cloudwatch_exporter_url, var.image_versions.cloudwatch-exporter)
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.cloudwatch_exporter_port])
    ulimits       = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "PROMETHEUS",
        "value" : "true"
      },
      {
        "name" : "CLOUDWATCH_EXPORTER_CONFIG_CHANGE_DEPENDENCY",
        "value" : "${md5(data.template_file.cloudwatch_exporter.rendered)}"
      },
      {
        "name" : "HTTP_PROXY",
        "value" : "http://${aws_vpc_endpoint.internet_proxy.dns_entry.dns_name}:${var.internet_proxy_port}"
      },
      {
        "name" : "HTTPS_PROXY",
        "value" : "http://${aws_vpc_endpoint.internet_proxy.dns_entry.dns_name}:${var.internet_proxy_port}"
      },
    ])
  }
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name                               = "cloudwatch-exporter"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.cloudwatch_exporter.arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.cloudwatch_exporter.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.cloudwatch_exporter.arn
    container_name = "cloudwatch-exporter"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "cloudwatch_exporter" {
  name = "cloudwatch-exporter"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}
