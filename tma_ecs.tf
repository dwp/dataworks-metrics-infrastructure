variable "tma_port" {
  default = 8080
}

variable "tma_task_cpu" {
  default = {
    development    = "512"
    qa             = "512"
    integration    = "512"
    preprod        = "512"
    production     = "512"
    management     = "2048"
    management-dev = "2048"
  }
}

variable "tma_task_memory" {
  default = {
    development    = "2048"
    qa             = "2048"
    integration    = "2048"
    preprod        = "2048"
    production     = "2048"
    management     = "2048"
    management-dev = "2048"
  }
}

resource "aws_ecs_task_definition" "ztma" {
  family                   = "ztmab"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.tma_task_cpu[local.environment]
  memory                   = var.tma_task_memory[local.environment]
  task_role_arn            = aws_iam_role.tma.arn
  execution_role_arn       = local.is_management_env ? data.terraform_remote_state.management.outputs.ecs_task_execution_role.arn : data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.ztma_definition.rendered}]"

  volume {
    name = "certificates"

    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }

#    placement_constraints {
#      type       = "memberOf"
#      expression = "attribute:instance-type == additional"
#    }

  tags = merge(local.tags, { Name = "name4tma" })
}

data "template_file" "ztma_definition" {
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "ztma_z_"
    group_name         = "ztma_a"
    cpu                = var.tma_task_cpu[local.environment]
    image_url          = "475593055014.dkr.ecr.eu-west-2.amazonaws.com/tma:latest"
    memory             = var.tma_task_memory[local.environment]
    memory_reservation = "1024"
    user               = "root"
    ports              = jsonencode([])
    ulimits            = jsonencode([])
    log_group          = "metrics/monitoring-log"
    essential          = true
    region             = "eu-west-2"
    config_bucket      = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
    mount_points = jsonencode([
      {
        "container_path" : "/certificates",
        "source_volume" : "certificates"
      }
    ])
    environment_variables = jsonencode([
      {
        "name" : "LOG_LEVEL",
        "value" : "INFO"
      },
      {
        "name" : "HTTP_PROXY",
        "value" : local.internet_proxy.url
      },
      {
        "name" : "HTTPS_PROXY",
        "value" : local.internet_proxy.url
      },
      {
        "name" : "NO_PROXY",
        "value" : local.no_proxy
      },
      {
        "name" : "AWS_DEFAULT_REGION",
        "value" : var.region
      },
      {
        "name" : "APPLICATION",
        "value" : "testtma"
      },
      {
        "name" : "ENVIRONMENT",
        "value" : local.environment
      },
      {
        "name" : "DEST_BUCKET",
        "value" : local.is_management_env ? data.terraform_remote_state.management.outputs.published_bucket.id : data.terraform_remote_state.common.outputs.published_bucket.id

      }
    ])
  }
}

resource "aws_ecs_service" "ztma" {
  name                               = "tma"
  cluster                            = "arn:aws:ecs:eu-west-2:483867336682:cluster/metrics"
  task_definition                    = aws_ecs_task_definition.ztma.arn
  desired_count                      = 1
  launch_type                        = "EC2"
  force_new_deployment               = true
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups = [aws_security_group.tma.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
    subnets         = module.vpc.outputs.private_subnets[local.secondary_role_index]
  }
  service_registries {
    registry_arn   = aws_service_discovery_service.cert_metrics.arn
    container_name = "ztma"
  }

  tags = merge(local.tags, {
    Name = "name4tma"
  })
}
