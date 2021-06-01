resource "aws_ecs_task_definition" "ingest_pushgateway" {
  count                    = local.is_management_env ? 0 : 1
  family                   = "ingest-pushgateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ingest_pushgateway_task_cpu[local.environment]
  memory                   = "4096"
  task_role_arn            = aws_iam_role.ingest_pushgateway[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.ingest_pushgateway_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "ingest_pushgateway_definition" {
  count    = local.is_management_env ? 0 : 1
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "ingest-pushgateway"
    group_name    = "pushgateway"
    cpu           = var.ingest_pushgateway_task_cpu[local.environment]
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

# resource "aws_ecs_service" "ingest_pushgateway" {
#   count                              = local.is_management_env ? 0 : 1
#   name                               = "ingest-pushgateway"
#   cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
#   task_definition                    = aws_ecs_task_definition.ingest_pushgateway[local.primary_role_index].arn
#   platform_version                   = var.platform_version
#   desired_count                      = 1
#   launch_type                        = "FARGATE"
#   deployment_minimum_healthy_percent = 100
#   deployment_maximum_percent         = 200

#   network_configuration {
#     security_groups = [data.terraform_remote_state.aws_ingestion.outputs.ingestion_vpc.vpce_security_groups.ingest_pushgateway_security_group.id]
#     subnets         = data.terraform_remote_state.aws_ingestion.outputs.ingestion_subnets.id
#   }

#   service_registries {
#     registry_arn   = aws_service_discovery_service.ingest_pushgateway[local.primary_role_index].arn
#     container_name = "ingest-pushgateway"
#   }

#   tags = merge(local.tags, { Name = var.name })
# }
