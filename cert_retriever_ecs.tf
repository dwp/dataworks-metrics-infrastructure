resource "aws_ecs_task_definition" "cert_retriever" {
  family                   = "cert_retriever"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.cert_retriever_task_cpu[local.environment]
  memory                   = var.cert_retriever_task_memory[local.environment]
  task_role_arn            = aws_iam_role.cert_retriever.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.cert_retriever_definition.rendered}]"

  volume {
    name = "cert_retriever"

    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }
  tags = merge(local.tags, { Name = var.name })
}

data "template_file" "cert_retriever_definition" {
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "cert_retriever"
    group_name         = "cert_retriever"
    cpu                = var.cert_retriever_cpu[local.environment]
    image_url          = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_acm_cert_helper_url, var.image_versions.cert_retriever)
    memory             = var.cert_retriever_memory[local.environment]
    memory_reservation = var.ec2_memory
    user               = "nobody"
    ports              = jsonencode([])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.monitoring_metrics.name
    essential          = true
    region             = data.aws_region.current.name
    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/cert_retriever",
        "source_volume" : "cert_retriever"
      }
    ])

    environment_variables = jsonencode([
      {
        "name" : "CERT_RETRIEVER_ROLE",
        "value" : "${local.roles[local.secondary_role_index]}"
      },
      {
        "name" : "LOG_LEVEL",
        "value" : "debug"
      }
    ])
  }
}

resource "aws_ecs_service" "cert_retriever" {
  name                               = "cert_retriever"
  cluster                            = aws_ecs_cluster.metrics_ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.cert_retriever.arn
  desired_count                      = 1
  launch_type                        = "EC2"
  force_new_deployment               = true
  deployment_minimum_healthy_percent = 66
  deployment_maximum_percent         = 133

  network_configuration {
    security_groups = [aws_security_group.cert_retriever.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.cert_retriever.arn
    container_name = "cert_retriever"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "cert_retriever" {
  name = "${local.environment}.cert_retriever.services.${var.parent_domain_name}"
  vpc  = module.vpc.outputs.vpcs[0].id
  tags = merge(local.tags, { Name = var.name })
}


resource "aws_service_discovery_service" "cert_retriever" {
  name = "cert-retriever"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cert_retriever.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}

