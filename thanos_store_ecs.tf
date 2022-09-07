resource "aws_ecs_task_definition" "thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "thanos-store"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.store_task_cpu[local.environment]
  memory                   = var.store_task_memory[local.environment]
  task_role_arn            = aws_iam_role.thanos_store[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.thanos_store_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })

  volume {
    name = "thanos-store"

    efs_volume_configuration {
      transit_encryption = "ENABLED"
      file_system_id     = aws_efs_file_system.thanos_store.id

      authorization_config {
        access_point_id = aws_efs_access_point.thanos_store.id
        iam             = "ENABLED"
      }
    }
  }
}

data "template_file" "thanos_store_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "thanos-store"
    group_name    = "thanos"
    cpu           = var.store_cpu[local.environment]
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_thanos_url, var.image_versions.thanos)
    memory        = var.store_memory[local.environment]
    user          = "nobody"
    ports         = jsonencode([var.thanos_port_grpc])
    ulimits       = jsonencode([var.ulimits])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([{ container_path = "/data/thanos", source_volume = "thanos-store" }])

    environment_variables = jsonencode([
      {
        "name" : "THANOS_MODE",
        "value" : "store"
      },
      {
        "name" : "THANOS_STORE_CONFIG_CHANGE_DEPENDENCY",
        "value" : md5(data.template_file.thanos_config.rendered)
      }
    ])
  }
}

resource "aws_ecs_service" "thanos_store" {
  count                              = local.is_management_env ? 1 : 0
  name                               = "thanos-store"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.thanos_store[local.primary_role_index].arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  force_new_deployment               = true
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

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

resource "aws_efs_file_system" "thanos_store" {
  creation_token = "thanos-store"

  tags = {
    Name = "thanos-store"
  }
}

resource "aws_efs_mount_target" "thanos_store" {
  count           = length(module.vpc.outputs.private_subnets[local.primary_role_index])
  file_system_id  = aws_efs_file_system.thanos_store.id
  subnet_id       = module.vpc.outputs.private_subnets[local.primary_role_index][count.index]
  security_groups = [aws_security_group.thanos_store_efs[0].id]
}

resource "aws_efs_access_point" "thanos_store" {
  file_system_id = aws_efs_file_system.thanos_store.id

  posix_user {
    gid = 65534
    uid = 65534
  }

  root_directory {
    path = "/data/thanos"

    creation_info {
      owner_uid   = 65534
      owner_gid   = 65534
      permissions = "755"
    }
  }
}
