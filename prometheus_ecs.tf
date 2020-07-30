resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.prometheus.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.prometheus_definition.rendered}, ${data.template_file.thanos_sidecar_prometheus_definition.rendered}, ${data.template_file.ecs_service_discovery_definition.rendered}]"
  volume {
    name = "prometheus"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.prometheus.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.prometheus.id
      }
    }
  }
}

data "template_file" "prometheus_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "prometheus"
    group_name    = "prometheus"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_prometheus_url
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.prometheus_port])
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/prometheus",
        "source_volume" : "prometheus"
      }
    ])

    environment_variables = jsonencode([
      {
        "name" : "PROMETHEUS_ROLE",
        "value" : "${local.roles[local.secondary_role_index]}"
      }
    ])
  }
}

data "template_file" "ecs_service_discovery_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "ecs-service-discovery"
    group_name    = "ecs_service_discovery"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_ecs_service_discovery_url
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/prometheus",
        "source_volume" : "prometheus"
      }
    ])

    environment_variables = jsonencode([
      {
        "name" : "SERVICE_DISCOVERY_DIRECTORY",
        "value" : "/prometheus/ecs"
      }
    ])
  }
}

data "template_file" "thanos_sidecar_prometheus_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "thanos-sidecar"
    group_name    = "thanos"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_thanos_url
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.thanos_port_grpc])
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/prometheus",
        "source_volume" : "prometheus"
      }
    ])

    environment_variables = jsonencode([])
  }
}

resource "aws_ecs_service" "prometheus" {
  name             = "prometheus"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.prometheus.arn
  platform_version = var.platform_version
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.prometheus.id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.prometheus.arn
    container_name = "prometheus"
  }
}

resource "aws_cloudwatch_log_group" "monitoring" {
  name = "${data.terraform_remote_state.management.outputs.ecs_cluster_main_log_group.name}/${var.name}"
  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "monitoring" {
  name = "${local.environment}.services.${var.parent_domain_name}"
  vpc  = module.vpc.outputs.vpcs[0].id
}

resource "aws_service_discovery_service" "prometheus" {
  name = "${var.name}-${local.roles[local.secondary_role_index]}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
