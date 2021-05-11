resource "aws_ecs_task_definition" "alertmanager_sns_forwarder" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "alertmanager-sns-forwarder"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.alertmanager_sns_forwarder[local.primary_role_index].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.alertmanager_sns_forwarder_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "alertmanager_sns_forwarder_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "alertmanager-sns-forwarder"
    group_name    = "alertmanager-sns-forwarder"
    cpu           = var.fargate_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.alertmanager_sns_forwarder_url, var.image_versions.alertmanager_sns_forwarder)
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([9087])
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

resource "aws_ecs_service" "alertmanager_sns_forwarder" {
  count                              = local.is_management_env ? 1 : 0
  name                               = "alertmanager-sns-forwarder"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.alertmanager_sns_forwarder[local.primary_role_index].arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.alertmanager_sns_forwarder[local.primary_role_index].id, aws_security_group.monitoring_common[local.primary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.alertmanager_sns_forwarder[local.primary_role_index].arn
    container_name = "alertmanager-sns-forwarder"
  }

  tags = merge(local.tags, { Name = var.name })
}


resource "aws_service_discovery_service" "alertmanager_sns_forwarder" {
  count = local.is_management_env ? 1 : 0
  name  = "alertmanager-sns-forwarder"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}


resource "aws_sns_topic" "test_forwarder_topic" {
  name         = "test_forwarder_topic"
  display_name = "test_forwarder_topic - ${terraform.workspace}"
}
