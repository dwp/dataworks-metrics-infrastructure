resource "aws_ecs_task_definition" "blackbox" {
  count                    = local.is_management_env ? 0 : 1
  family                   = "blackbox"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  task_role_arn            = aws_iam_role.blackbox[0].arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.blackbox_definition[0].rendered}, ${data.template_file.acm_cert_helper_definition[0].rendered}]"

  volume {
    name = "certs"
  }

  tags = merge(local.tags, { Name = var.name })
}

data "template_file" "blackbox_definition" {
  count    = local.is_management_env ? 0 : 1
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "blackbox"
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

    mount_points = jsonencode([
      {
        "container_path" : "/acm-cert-helper",
        "source_volume" : "certs"
      }
    ])

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
        value = "DEBUG"
      }
    ])
  }
}

data "template_file" "acm_cert_helper_definition" {
  count    = local.is_management_env ? 0 : 1
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "acm_cert_helper"
    group_name    = "acm_cert_helper"
    cpu           = var.fargate_cpu
    image_url     = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_acm_cert_helper_url, var.image_versions.acm-cert-helper)
    memory        = var.fargate_memory
    user          = "root"
    ports         = jsonencode([])
    ulimits       = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/acm-cert-helper",
        "source_volume" : "certs"
      }
    ])

    environment_variables = jsonencode([
      {
        "name" : "HTTP_PROXY",
        "value" : "http://${aws_vpc_endpoint.non_mgmt_internet_proxy[0].dns_entry[0].dns_name}:${var.internet_proxy_port}"
      },
      {
        "name" : "HTTPS_PROXY",
        "value" : "http://${aws_vpc_endpoint.non_mgmt_internet_proxy[0].dns_entry[0].dns_name}:${var.internet_proxy_port}"
      },
      {
        "name" : "NO_PROXY",
        "value" : "127.0.0.1,${local.sdx_non_proxied_endpoints},${local.environment}.services.${var.parent_domain_name}"
      },
      {
        name  = "PROMETHEUS",
        value = "true"
      },
      {
        name  = "LOG_LEVEL",
        value = "DEBUG"
      },
      {
        name  = "ACM_CERT_ARN",
        value = "${data.terraform_remote_state.snapshot_sender.outputs.ss_cert[0].arn}"
      },
      {
        name  = "PRIVATE_KEY_ALIAS",
        value = "${local.environment}"
      },
      {
        name  = "TRUSTSTORE_ALIASES",
        value = "${local.ss_host_truststore_aliases[local.environment]}"
      },
      {
        name  = "TRUSTSTORE_CERTS",
        value = "${local.ss_host_truststore_certs[local.environment]}"
      }
    ])
  }
}

resource "aws_ecs_service" "blackbox" {
  count                              = local.is_management_env ? 0 : 1
  name                               = "blackbox"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.blackbox[0].arn
  platform_version                   = var.platform_version
  desired_count                      = 1
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.blackbox[0].id, data.terraform_remote_state.snapshot_sender.outputs.security_group.snapshot_sender]
    subnets         = data.terraform_remote_state.aws_sdx.outputs.subnet_sdx_connectivity.*.id
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.blackbox[0].arn
    container_name = "blackbox"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "blackbox" {
  count = local.is_management_env ? 0 : 1
  name  = "blackbox"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sdx_services[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}
