//resource "aws_ecs_task_definition" "hbase_exporter" {
//  count                    = local.is_management_env ? 0 : 1
//  family                   = "hbase-exporter"
//  network_mode             = "awsvpc"
//  requires_compatibilities = ["FARGATE"]
//  cpu                      = "512"
//  memory                   = "4096"
//  task_role_arn            = aws_iam_role.hbase_exporter[local.secondary_role_index].arn
//  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
//  container_definitions    = "[${data.template_file.hbase_exporter_definition[local.secondary_role_index].rendered}]"
//  tags                     = merge(local.tags, { Name = var.name })
//}
//
//data "template_file" "hbase_exporter_definition" {
//  count    = local.is_management_env ? 0 : 1
//  template = file("${path.module}/container_definition.tpl")
//  vars = {
//    name          = "hbase-exporter"
//    group_name    = "json_exporter"
//    cpu           = var.fargate_cpu
//    image_url     = data.terraform_remote_state.management.outputs.ecr_hive_exporter_url
//    memory        = var.fargate_memory
//    user          = "nobody"
//    ports         = jsonencode([var.json_exporter_port])
//    ulimits       = jsonencode([])
//    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
//    region        = data.aws_region.current.name
//    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
//
//    mount_points = jsonencode([])
//
//    environment_variables = jsonencode([
//      {
//        "name" : "PROMETHEUS",
//        "value" : "true"
//      },
//      {
//        "name" : "CONFIG_FILE",
//        "value" : "hbase_config.yml"
//      },
//      {
//        "name" : "HBASE_CONFIG_CHANGE_DEPENDENCY",
//        "value" : "${md5(data.template_file.hbase_exporter[local.secondary_role_index].rendered)}"
//      }
//    ])
//  }
//}
//
//resource "aws_ecs_service" "hbase_exporter" {
//  count            = local.is_management_env ? 0 : 1
//  name             = "hbase-exporter"
//  cluster          = aws_ecs_cluster.metrics_ecs_cluster.id
//  task_definition  = aws_ecs_task_definition.hbase_exporter[local.secondary_role_index].arn
//  platform_version = var.platform_version
//  desired_count    = 1
//  launch_type      = "FARGATE"
//
//  network_configuration {
//    security_groups = [aws_security_group.hbase_exporter[local.secondary_role_index].id, aws_security_group.monitoring_common[local.secondary_role_index].id]
//    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
//  }
//
//  service_registries {
//    registry_arn   = aws_service_discovery_service.hbase_exporter[local.secondary_role_index].arn
//    container_name = "hbase-exporter"
//  }
//
//  tags = merge(local.tags, { Name = var.name })
//}
//
//resource "aws_service_discovery_service" "hbase_exporter" {
//  count = local.is_management_env ? 0 : 1
//  name  = "hbase-exporter"
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
