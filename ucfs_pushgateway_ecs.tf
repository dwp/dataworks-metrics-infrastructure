resource "aws_ecs_task_definition" "ucfs_claimant_api_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  family                   = "ucfs-claimant-api-pushgateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.ucfs_claimant_api_pushgateway[0].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.ucfs_claimant_api_pushgateway_definition[0].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "ucfs_claimant_api_pushgateway_definition" {
  count    = local.is_management_env ? 0 : 1
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "ucfs-claimant-api-pushgateway"
    group_name    = "pushgateway"
    cpu           = var.fargate_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_pushgateway_url, var.image_versions.prom-pushgateway)
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.pushgateway_port])
    ulimits       = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
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

resource "aws_ecs_service" "ucfs_claimant_api_pushgateway" {
  count                              = local.is_management_env ? 0 : 1
  name                               = "ucfs-claimant-api-pushgateway"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.ucfs_claimant_api_pushgateway[0].arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [data.terraform_remote_state.ucfs-claimant.outputs.vpce_security_groups.ucfs_claimant_api_pushgateway.id]
    subnets         = data.terraform_remote_state.ucfs-claimant.outputs.subnet_ucfs_claimant_api_connectivity.*.id
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.ucfs_claimant_api_pushgateway[0].arn
    container_name = "ucfs-claimant-api-pushgateway"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "ucfs_claimant_api_services" {
  count = local.is_management_env ? 0 : 1
  name  = "${local.environment}.ucfs-claimant.services.${var.parent_domain_name}"
  vpc   = data.terraform_remote_state.ucfs-claimant.outputs.ucfs_claimant_api_vpc.vpc.id
  tags  = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "ucfs_claimant_api_pushgateway" {
  count = local.is_management_env ? 0 : 1
  name  = "ucfs-claimant-api-pushgateway"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ucfs_claimant_api_services[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}

output "ucfs_claimant_api_pushgateway_discovery" {
  value = {
    name = aws_service_discovery_service.ucfs_claimant_api_pushgateway.name
  }
}

output "ucfs_claimant_api_pushgateway_discovery_dns" {
  value = {
    name = aws_service_discovery_private_dns_namespace.ucfs_claimant_api_services.name
  }
}
