resource "aws_ecs_task_definition" "thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "thanos-ruler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.thanos_ruler[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.thanos_ruler_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "thanos_ruler_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "thanos-ruler"
    group_name    = "thanos"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_thanos_url
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.thanos_port_http])
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "THANOS_MODE",
        "value" : "rule"
      },
      {
        "name" : "QUERY_URL",
        "value" : "thanos-query.${local.environment}.services.${var.parent_domain_name}:${var.thanos_port_http}"
      },
      {
        "name" : "ALERTMANAGER_URL",
        "value" : "alertmanager.${local.environment}.services.${var.parent_domain_name}:${var.alertmanager_port}"
      }
    ])
  }
}

resource "aws_ecs_service" "thanos_ruler" {
  count            = local.is_management_env ? 1 : 0
  name             = "thanos-ruler"
  cluster          = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.thanos_ruler[local.primary_role_index].arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.thanos_ruler[0].id, aws_security_group.monitoring_common[local.primary_role_index].id]
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

  tags = merge(local.tags, { Name = var.name })
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

  tags = merge(local.tags, { Name = var.name })
}
