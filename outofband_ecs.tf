resource "aws_ecs_task_definition" "outofband" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "outofband"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.outofband[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.outofband_definition[local.primary_role_index].rendered}, ${data.template_file.thanos_receiver_outofband_definition[local.primary_role_index].rendered}]"

  volume {
    name = "outofband"
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
    //    efs_volume_configuration {
    //      file_system_id     = aws_efs_file_system.prometheus.id
    //      root_directory     = "/"
    //      transit_encryption = "ENABLED"
    //      authorization_config {
    //        access_point_id = aws_efs_access_point.prometheus.id
    //      }
    //    }
  }
  tags = merge(local.tags, { Name = var.name })
}

data "template_file" "outofband_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "outofband"
    group_name    = "prometheus"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_prometheus_url
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.prometheus_port])
    ulimits       = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/prometheus",
        "source_volume" : "outofband"
      }
    ])

    environment_variables = jsonencode([
      {
        "name" : "PROMETHEUS_ROLE",
        "value" : "outofband"
      },
      {
        "name" : "OUTOFBAND_CONFIG_CHANGE_DEPENDENCY",
        "value" : "${md5(data.template_file.outofband.rendered)}"
      }
    ])
  }
}

data "template_file" "thanos_receiver_outofband_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "thanos-receiver"
    group_name         = "thanos"
    cpu                = var.fargate_cpu
    image_url          = data.terraform_remote_state.management.outputs.ecr_thanos_url
    memory             = var.receiver_memory
    memory_reservation = var.fargate_memory
    user               = "nobody"
    ports              = jsonencode([var.thanos_port_grpc, var.thanos_port_remote_write])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.monitoring.name
    region             = data.aws_region.current.name
    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/prometheus",
        "source_volume" : "outofband"
      }
    ])

    environment_variables = jsonencode([])
  }
}

resource "aws_ecs_service" "outofband" {
  count            = local.is_management_env ? 1 : 0
  name             = "outofband"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.outofband[local.primary_role_index].arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.outofband[local.primary_role_index].id, aws_security_group.monitoring_common[local.primary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.outofband[local.primary_role_index].arn
    container_name   = "outofband"
    container_port   = var.prometheus_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.outofband[local.primary_role_index].arn
    container_name = "outofband"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "outofband" {
  count = local.is_management_env ? 1 : 0
  name  = "outofband"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}
