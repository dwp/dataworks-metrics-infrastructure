resource "aws_ecs_task_definition" "thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "thanos-store"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
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
        "value" : "store"
      },
      {
        "name" : "STORE_HOSTNAMES",
        "value" : "${join(" ", formatlist("${var.name}-${var.secondary}.%s.services.${var.parent_domain_name}", "${local.master_peerings[local.slave_peerings[local.environment]]}"))}"
      },
      {
        "name" : "THANOS_STORE_CONFIG_CHANGE_DEPENDENCY",
        "value" : "${md5(data.template_file.thanos_store.rendered)}"
      }
    ])
  }
}

resource "aws_ecs_service" "thanos_store" {
  count            = local.is_management_env ? 1 : 0
  name             = "thanos-store"
  cluster          = data.terraform_remote_state.management.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.thanos_store[local.primary_role_index].arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.thanos_store[0].id, aws_security_group.monitoring_common[local.primary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.thanos_store[local.primary_role_index].arn
    container_name   = "thanos-store"
    container_port   = var.prometheus_port
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
