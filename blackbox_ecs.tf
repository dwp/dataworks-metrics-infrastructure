resource "aws_ecs_task_definition" "blackbox" {
  count                    = local.is_management_env ? 0 : 1
  family                   = "blackbox"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  task_role_arn            = aws_iam_role.blackbox[0].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.blackbox_definition[0].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "blackbox_definition" {
  count    = local.is_management_env ? 0 : 1
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "blackbox"
    group_name    = "blackbox"
    cpu           = var.fargate_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_blackbox_exporter_url, var.image_versions.blackbox)
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([9115])
    ulimits       = jsonencode([])
    mount_points  = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    environment_variables = jsonencode([
      {
        "name" : "BLACKBOX_CONFIG_CHANGE_DEPENDENCY",
        "value" : md5(data.template_file.blackbox.rendered)
      },
      {
        name  = "PROMETHEUS",
        value = "true"
      },
      {
        name  = "LOG_LEVEL",
        value = "debug"
      }
    ])
  }
}

resource "aws_ecs_service" "blackbox" {
  count                              = local.is_management_env ? 0 : 1
  name                               = "blackbox"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.blackbox[0].arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [data.terraform_remote_state.aws_sdx.outputs.vpce_security_groups.blackbox_vpce_security_group.id, data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender]
    subnets         = data.terraform_remote_state.aws_sdx.outputs.subnet_sdx_connectivity.*.id
  }

  service_registries {
    registry_arn   = data.terraform_remote_state.aws_sdx.outputs.private_dns.blackbox_service_discovery.arn
    container_name = "blackbox"
  }

  tags = merge(local.tags, { Name = var.name })
}
