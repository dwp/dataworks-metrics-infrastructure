resource "aws_ecs_task_definition" "cert_metrics" {
  family                   = "cert_metrics"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.cert_metrics_task_cpu[local.environment]
  memory                   = var.cert_metrics_task_memory[local.environment]
  task_role_arn            = aws_iam_role.cert_metrics.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.cert_retriever_definition.rendered}, ${data.template_file.cert_exporter_definition.rendered}]"

  volume {
    name = "certificates"

    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:instance-type == additional"
  }

  tags = merge(local.tags, { Name = var.name })
}

data "template_file" "cert_retriever_definition" {
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "cert_retriever"
    group_name         = "cert_retriever"
    cpu                = var.cert_retriever_cpu[local.environment]
    image_url          = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_cert_retriever_url, var.image_versions.cert_retriever)
    memory             = var.cert_retriever_memory[local.environment]
    memory_reservation = var.ec2_memory
    user               = "root"
    ports              = jsonencode([])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.monitoring_metrics.name
    essential          = false
    region             = data.aws_region.current.name
    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/certificates",
        "source_volume" : "certificates"
      }
    ])

    environment_variables = jsonencode([
      {
        "name" : "CERT_RETRIEVER_ROLE",
        "value" : "${local.roles[local.secondary_role_index]}"
      },
      {
        "name" : "LOG_LEVEL",
        "value" : "INFO"
      },
      {
        "name" : "HTTP_PROXY",
        "value" : "${local.internet_proxy.url}"
      },
      {
        "name" : "HTTPS_PROXY",
        "value" : "${local.internet_proxy.url}"
      },
      {
        "name" : "NO_PROXY",
        "value" : "${local.no_proxy}"
      },
      {
        "name" : "AWS_DEFAULT_REGION",
        "value" : "${var.region}"
      },
      {
        "name" : "APPLICATION",
        "value" : "${var.name}"
      },
      {
        "name" : "ENVIRONMENT",
        "value" : "${local.environment}"
      },
      {
        "name" : "CERTS_DESTINATION_FOLDER",
        "value" : "/certificates"
      },
      {
        name  = "PROMETHEUS",
        value = "true"
      }
    ])
  }
}

data "template_file" "cert_exporter_definition" {
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "cert_exporter"
    group_name         = "cert_exporter"
    cpu                = var.cert_exporter_cpu[local.environment]
    image_url          = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_cert_exporter_url, var.image_versions.cert_exporter)
    memory             = var.cert_exporter_memory[local.environment]
    memory_reservation = var.ec2_memory
    user               = "root"
    ports              = jsonencode([8080])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.monitoring_metrics.name
    essential          = true
    region             = data.aws_region.current.name
    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/certificates",
        "source_volume" : "certificates"
      }
    ])

    environment_variables = jsonencode([
      {
        "name" : "CERT_EXPORTER_ROLE",
        "value" : "${local.roles[local.secondary_role_index]}"
      },
      {
        "name" : "LOG_LEVEL",
        "value" : "INFO"
      },
      {
        "name" : "HTTP_PROXY",
        "value" : "${local.internet_proxy.url}"
      },
      {
        "name" : "HTTPS_PROXY",
        "value" : "${local.internet_proxy.url}"
      },
      {
        "name" : "NO_PROXY",
        "value" : "${local.no_proxy}"
      },
      {
        "name" : "AWS_DEFAULT_REGION",
        "value" : "${var.region}"
      },
      {
        "name" : "APPLICATION",
        "value" : "${var.name}"
      },
      {
        "name" : "ENVIRONMENT",
        "value" : "${local.environment}"
      },
      {
        name  = "PROMETHEUS",
        value = "true"
      }
    ])
  }
}

resource "aws_ecs_service" "cert_metrics" {
  name                               = "cert_metrics"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.cert_metrics.arn
  desired_count                      = 1
  launch_type                        = "EC2"
  force_new_deployment               = false
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [local.is_management_env ? aws_security_group.cert_metrics[local.primary_role_index].id : aws_security_group.cert_metrics[local.secondary_role_index].id, aws_security_group.monitoring_common[local.secondary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.cert_metrics.arn
    container_name = "cert_metrics"
  }

  tags = merge(local.tags, {
    Name = var.name
  })
}

resource "aws_service_discovery_service" "cert_metrics" {
  name = "cert-metrics"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}

