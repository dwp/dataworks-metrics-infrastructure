//resource "aws_ecs_task_definition" "prometheus" {
//  family                   = "prometheus"
//  network_mode             = "awsvpc"
//  requires_compatibilities = ["EC2"]
//  cpu                      = "2048"
//  memory                   = "4096"
//  task_role_arn            = aws_iam_role.prometheus.arn
//  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
//  container_definitions    = "[${data.template_file.prometheus_definition.rendered}, ${data.template_file.thanos_receiver_prometheus_definition.rendered}, ${data.template_file.ecs_service_discovery_definition.rendered}]"
//
//  volume {
//    name = "prometheus"
//
//    docker_volume_configuration {
//      scope         = "shared"
//      autoprovision = true
//      driver        = "local"
//    }
//  }
//
//  tags = merge(local.tags, { Name = var.name })
//}
//
//data "template_file" "prometheus_definition" {
//  template = file("${path.module}/reserved_container_definition.tpl")
//  vars = {
//    name               = "prometheus"
//    group_name         = "prometheus"
//    cpu                = var.fargate_cpu
//    image_url          = data.terraform_remote_state.management.outputs.ecr_prometheus_url
//    memory             = var.receiver_memory
//    memory_reservation = var.fargate_memory
//    user               = "nobody"
//    ports              = jsonencode([var.prometheus_port])
//    ulimits            = jsonencode([])
//    log_group          = aws_cloudwatch_log_group.monitoring_metrics.name
//    region             = data.aws_region.current.name
//    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
//
//    mount_points = jsonencode([
//      {
//        "container_path" : "/prometheus",
//        "source_volume" : "prometheus"
//      }
//    ])
//
//    environment_variables = jsonencode([
//      {
//        "name" : "PROMETHEUS_ROLE",
//        "value" : "${local.roles[local.secondary_role_index]}"
//      }
//    ])
//  }
//}
//
//data "template_file" "ecs_service_discovery_definition" {
//  template = file("${path.module}/reserved_container_definition.tpl")
//  vars = {
//    name               = "ecs-service-discovery"
//    group_name         = "ecs_service_discovery"
//    cpu                = var.fargate_cpu
//    image_url          = data.terraform_remote_state.management.outputs.ecr_ecs_service_discovery_url
//    memory             = var.receiver_memory
//    memory_reservation = var.fargate_memory
//    user               = "nobody"
//    ports              = jsonencode([])
//    ulimits            = jsonencode([])
//    log_group          = aws_cloudwatch_log_group.monitoring_metrics.name
//    region             = data.aws_region.current.name
//    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
//
//    mount_points = jsonencode([
//      {
//        "container_path" : "/prometheus",
//        "source_volume" : "prometheus"
//      }
//    ])
//
//    environment_variables = jsonencode([
//      {
//        "name" : "SERVICE_DISCOVERY_DIRECTORY",
//        "value" : "/prometheus/ecs"
//      },
//      {
//        "name" : "PROMETHEUS_CONFIG_CHANGE_DEPENDENCY",
//        "value" : "${md5(data.template_file.prometheus.rendered)}"
//      },
//      {
//        "name" : "AWS_DEFAULT_REGION",
//        "value" : "eu-west-2"
//      }
//    ])
//  }
//}
//
//data "template_file" "thanos_receiver_prometheus_definition" {
//  template = file("${path.module}/reserved_container_definition.tpl")
//  vars = {
//    name               = "thanos-receiver"
//    group_name         = "thanos"
//    cpu                = var.fargate_cpu
//    image_url          = data.terraform_remote_state.management.outputs.ecr_thanos_url
//    memory             = var.receiver_memory
//    memory_reservation = var.fargate_memory
//    user               = "nobody"
//    ports              = jsonencode([var.thanos_port_grpc, var.thanos_port_remote_write])
//    ulimits            = jsonencode([])
//    log_group          = aws_cloudwatch_log_group.monitoring_metrics.name
//    region             = data.aws_region.current.name
//    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
//
//    mount_points = jsonencode([
//      {
//        "container_path" : "/prometheus",
//        "source_volume" : "prometheus"
//      }
//    ])
//
//    environment_variables = jsonencode([
//      {
//        "name" : "THANOS_STORE_CONFIG_CHANGE_DEPENDENCY",
//        "value" : "${md5(data.template_file.thanos_config.rendered)}"
//      },
//      {
//        "name" : "THANOS_ALLOW_EXISTING_BUCKET_USE"
//        "value" : "true"
//      },
//      {
//        "name" : "RECEIVE_ENV"
//        "value" : "${local.environment}"
//      }
//    ])
//  }
//}
//
//resource "aws_ecs_service" "prometheus" {
//  name            = "prometheus"
//  cluster         = aws_ecs_cluster.metrics_ecs_cluster.id
//  task_definition = aws_ecs_task_definition.prometheus.arn
//  # platform_version = var.platform_version
//  desired_count = 1
//  launch_type   = "EC2"
//
//  network_configuration {
//    security_groups = [aws_security_group.prometheus.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
//    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
//  }
//
//  service_registries {
//    registry_arn   = aws_service_discovery_service.prometheus.arn
//    container_name = "prometheus"
//  }
//
//  tags = merge(local.tags, { Name = var.name })
//}
//
//#TODO remove this log-group as it is no longer being written to by this repo
//resource "aws_cloudwatch_log_group" "monitoring" {
//  name = "${data.terraform_remote_state.management.outputs.ecs_cluster_main_log_group.name}/${var.name}"
//  tags = merge(local.tags, { Name = var.name })
//}
//
resource "aws_cloudwatch_log_group" "monitoring_metrics" {
  name = "${aws_ecs_cluster.metrics_ecs_cluster.name}/${var.name}-log"
  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "monitoring" {
  name = "${local.environment}.services.${var.parent_domain_name}"
  vpc  = module.vpc.outputs.vpcs[0].id
  tags = merge(local.tags, { Name = var.name })
}
//
//resource "aws_service_discovery_service" "prometheus" {
//  name = "${var.name}-${local.roles[local.secondary_role_index]}"
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
