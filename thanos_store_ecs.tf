resource "aws_ecs_task_definition" "thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "thanos-store"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.thanos_store[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.thanos_store_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "thanos_store_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "thanos-store"
    group_name    = "thanos"
    cpu           = var.store_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_thanos_url, var.image_versions.thanos)
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.thanos_port_grpc])
    ulimits       = jsonencode([var.ulimits])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "THANOS_MODE",
        "value" : "store"
      },
      {
        "name" : "THANOS_STORE_CONFIG_CHANGE_DEPENDENCY",
        "value" : "${md5(data.template_file.thanos_config.rendered)}"
      }
    ])
  }
}

resource "aws_ecs_service" "thanos_store" {
  count            = local.is_management_env ? 1 : 0
  name             = "thanos-store"
  cluster          = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition  = aws_ecs_task_definition.thanos_store[local.primary_role_index].arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"
  force_new_deployment = true

  network_configuration {
    security_groups = [aws_security_group.thanos_store[0].id, aws_security_group.monitoring_common[local.primary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.thanos_store[local.primary_role_index].arn
    container_name = "thanos-store"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "thanos_store" {
  count = local.is_management_env ? 1 : 0
  name  = "thanos-store"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}
