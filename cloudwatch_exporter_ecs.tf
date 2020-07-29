resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                   = "cloudwatch-exporter"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.cloudwatch_exporter.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.cloudwatch_exporter_definition.rendered}]"
}

data "template_file" "cloudwatch_exporter_definition" {
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "cloudwatch-exporter"
    group_name    = "cloudwatch_exporter"
    cpu           = var.fargate_cpu
    image_url     = data.terraform_remote_state.management.outputs.ecr_cloudwatch_exporter_url
    memory        = var.fargate_memory
    user          = "nobody"
    ports         = jsonencode([var.cloudwatch_exporter_port])
    log_group     = aws_cloudwatch_log_group.monitoring.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "PROMETHEUS",
        "value" : "true"
      }
    ])
  }
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name             = "cloudwatch-exporter"
  cluster          = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_cluster_main.id : data.terraform_remote_state.common.outputs.ecs_cluster_main.id
  task_definition  = aws_ecs_task_definition.cloudwatch_exporter.arn
  platform_version = "1.4.0"
  desired_count    = 1
  launch_type      = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.cloudwatch_exporter.id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.cloudwatch_exporter.arn
    container_name = "cloudwatch-exporter"
  }
}

resource "aws_service_discovery_service" "cloudwatch_exporter" {
  name = "cloudwatch-exporter"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
