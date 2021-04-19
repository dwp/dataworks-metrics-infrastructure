resource "aws_ecs_task_definition" "blackbox_concourse" {
  count                    = local.is_management_env ? 1 : 0
  family                   = "blackbox"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  task_role_arn            = aws_iam_role.blackbox_concourse[0].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.blackbox_concourse_definition[0].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "blackbox_concourse_definition" {
  count    = local.is_management_env ? 1 : 0
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "blackbox-concourse"
    group_name    = "blackbox"
    cpu           = var.fargate_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_blackbox_exporter_url, var.image_versions.blackbox)
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([9115])
    ulimits       = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([
      {
        "name" : "BLACKBOX_CONFIG_CHANGE_DEPENDENCY",
        "value" : "${md5(data.template_file.blackbox.rendered)}"
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

resource "aws_ecs_service" "blackbox_concourse" {
  count                              = local.is_management_env ? 1 : 0
  name                               = "blackbox-concourse"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.blackbox_concourse[0].arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.blackbox_concourse[0].id, data.terraform_remote_state.aws_concourse.outputs.concourse_web_sg]
    subnets         = data.terraform_remote_state.aws_concourse.outputs.subnets_private.*.id
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.blackbox_concourse[0].arn
    container_name = "blackbox-concourse"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "concourse_services" {
  count = local.is_management_env ? 1 : 0
  name  = "${local.environment}.concourse.services.${var.parent_domain_name}"
  vpc   = data.terraform_remote_state.aws_concourse.outputs.aws_vpc.id
  tags  = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "blackbox_concourse" {
  count = local.is_management_env ? 1 : 0
  name  = "blackbox-concourse"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.concourse_services[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}
