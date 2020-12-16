resource "aws_ecs_task_definition" "adg_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  family                   = "adg-pushgateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.adg_pushgateway[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.adg_pushgateway_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "adg_pushgateway_definition" {
  count    = local.is_management_env ? 0 : 1
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "adg-pushgateway"
    group_name    = "pushgateway"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_pushgateway_url
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.pushgateway_port])
    ulimits       = jsonencode()
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        name  = "PROMETHEUS",
        value = "true"
      }
    ])
  }
}

resource "aws_ecs_service" "adg_pushgateway" {
  count            = local.is_management_env ? 0 : 1
  name             = "adg-pushgateway"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.adg_pushgateway[local.primary_role_index].arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.adg_pushgateway[local.primary_role_index].id]
    subnets         = data.terraform_remote_state.aws_internal_compute.outputs.adg_subnet.ids
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.adg_pushgateway[local.primary_role_index].arn
    container_name = "adg-pushgateway"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "adg_services" {
  count = local.is_management_env ? 0 : 1
  name  = "${local.environment}.adg.services.${var.parent_domain_name}"
  vpc   = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  tags  = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "adg_pushgateway" {
  count = local.is_management_env ? 0 : 1
  name  = "adg-pushgateway"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.adg_services[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}
