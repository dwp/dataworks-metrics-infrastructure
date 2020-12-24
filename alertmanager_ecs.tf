//resource "aws_ecs_task_definition" "alertmanager" {
//  count                    = local.is_management_env ? 1 : 0
//  family                   = "alertmanager"
//  network_mode             = "awsvpc"
//  requires_compatibilities = ["FARGATE"]
//  cpu                      = "512"
//  memory                   = "4096"
//  task_role_arn            = aws_iam_role.alertmanager[local.primary_role_index].arn
//  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
//  container_definitions    = "[${data.template_file.alertmanager_definition[local.primary_role_index].rendered}]"
//  tags                     = merge(local.tags, { Name = var.name })
//}
//
//data "template_file" "alertmanager_definition" {
//  count    = local.is_management_env ? 1 : 0
//  template = file("${path.module}/container_definition.tpl")
//  vars = {
//    name          = "alertmanager"
//    group_name    = "alertmanager"
//    cpu           = var.fargate_cpu
//    image_url     = data.terraform_remote_state.management.outputs.ecr_alertmanager_url
//    memory        = var.fargate_memory
//    user          = "nobody"
//    ports         = jsonencode([var.alertmanager_port])
//    ulimits       = jsonencode([])
//    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
//    region        = data.aws_region.current.name
//    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
//
//    mount_points = jsonencode([])
//
//    environment_variables = jsonencode([
//      {
//        name  = "ALERTMANAGER_DOMAIN",
//        value = "https://${aws_route53_record.alertmanager_loadbalancer[0].fqdn}"
//      },
//      {
//        "name" : "ALERTMANAGER_CONFIG_CHANGE_DEPENDENCY",
//        "value" : "${md5(data.template_file.alertmanager[local.primary_role_index].rendered)}"
//      }
//    ])
//  }
//}
//
//resource "aws_ecs_service" "alertmanager" {
//  count            = local.is_management_env ? 1 : 0
//  name             = "alertmanager"
//  cluster          = aws_ecs_cluster.metrics_ecs_cluster.id
//  task_definition  = aws_ecs_task_definition.alertmanager[local.primary_role_index].arn
//  platform_version = var.platform_version
//  desired_count    = 1
//  launch_type      = "FARGATE"
//
//  network_configuration {
//    security_groups = [aws_security_group.alertmanager[0].id, aws_security_group.monitoring_common[local.primary_role_index].id]
//    subnets         = module.vpc.outputs.private_subnets[local.primary_role_index]
//  }
//
//  load_balancer {
//    target_group_arn = aws_lb_target_group.alertmanager[local.primary_role_index].arn
//    container_name   = "alertmanager"
//    container_port   = var.alertmanager_port
//  }
//
//  service_registries {
//    registry_arn   = aws_service_discovery_service.alertmanager[local.primary_role_index].arn
//    container_name = "alertmanager"
//  }
//
//  tags = merge(local.tags, { Name = var.name })
//}
//
//resource "aws_service_discovery_service" "alertmanager" {
//  count = local.is_management_env ? 1 : 0
//  name  = "alertmanager"
//
//  dns_config {
//    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id
//
//    dns_records {
//      ttl  = 10
//      type = "A"
//    }
//  }
//
//  tags = merge(local.tags, { Name = var.name })
//}
