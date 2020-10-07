resource "aws_ecs_task_definition" "grafana" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.grafana[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.grafana_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "grafana_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "grafana"
    group_name    = "grafana"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_grafana_url
    memory        = var.fargate_memory
    user          = "grafana"
    ports         = jsonencode([var.grafana_port])
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "HTTP_PROXY",
        "value" : "http://${aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name}:${var.internet_proxy_port}"
      },
      {
        "name" : "HTTPS_PROXY",
        "value" : "http://${aws_vpc_endpoint.internet_proxy[0].dns_entry[0].dns_name}:${var.internet_proxy_port}"
      },
      {
        "name" : "NO_PROXY",
        "value" : "127.0.0.1,s3.${var.region}.amazonaws.com,secretsmanager.${var.region}.amazonaws.com,${local.environment}.services.${var.parent_domain_name}"
      },
      {
        "name" : "GRAFANA_CONFIG_CHANGE_DEPENDENCY",
        "value" : "${md5(data.template_file.grafana[local.primary_role_index].rendered)}"
      },
      {
        "name" : "SECRET_ID",
        "value" : "/concourse/dataworks/monitoring"
      }
    ])
  }
}

resource "aws_ecs_service" "grafana" {
  count            = local.is_management_env ? 1 : 0
  name             = "grafana"
  cluster          = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.grafana[local.primary_role_index].arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.grafana[0].id, aws_security_group.monitoring_common[local.primary_role_index].id]
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

  tags = merge(local.tags, { Name = var.name })
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

  tags = merge(local.tags, { Name = var.name })
}
