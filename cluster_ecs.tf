resource "aws_ecs_cluster" "metrics_ecs_cluster" {
  name               = local.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.metrics_cluster.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.metrics_cluster.name
  }

  tags = merge(
    local.tags,
    {
      Name = local.metrics_ecs_friendly_name
    }
  )

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "metrics_ecs_cluster" {
  name              = local.cw_agent_log_group_name_metrics_ecs
  retention_in_days = 180
  tags              = local.tags
}

resource "aws_ecs_capacity_provider" "metrics_cluster" {
  name = local.metrics_friendly_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.metrics_cluster.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }

  lifecycle {
    ignore_changes = all
  }

  tags = merge(
    local.tags,
    {
      Name = local.metrics_friendly_name
    }
  )
}

resource "aws_autoscaling_group" "metrics_cluster" {
  name                      = local.metrics_friendly_name
  min_size                  = var.desired_capacity[local.environment]
  desired_capacity          = var.desired_capacity[local.environment]
  max_size                  = var.metrics_ecs_cluster_asg_max[local.environment]
  protect_from_scale_in     = true
  health_check_grace_period = 600
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = module.vpc.outputs.private_subnets[local.secondary_role_index]

  launch_template {
    id      = aws_launch_template.metrics_cluster.id
    version = aws_launch_template.metrics_cluster.latest_version
  }

  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = local.metrics_ecs_asg_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_template" "metrics_cluster" {
  name          = local.metrics_friendly_name
  image_id      = var.ecs_hardened_ami_id
  instance_type = var.metrics_ecs_cluster_ec2_size[local.environment]

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [
      aws_security_group.metrics_cluster.id,
    ]
  }

  user_data = base64encode(templatefile("userdata.tpl", {
    cluster_name = local.cluster_name # Referencing the cluster resource causes a circular dependency
  }))

  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    arn = aws_iam_instance_profile.metrics_cluster.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 1024
      volume_type           = "io1"
      iops                  = "2000"
      delete_on_termination = true
      encrypted             = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = local.metrics_friendly_name
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.tags,
      {
        Name                = local.metrics_friendly_name,
        AutoShutdown        = local.metrics_ecs_cluster_asg_autoshutdown[local.environment],
        SSMEnabled          = local.metrics_ecs_cluster_asg_ssmenabled[local.environment],
        Persistence         = "Ignore",
        propagate_at_launch = true,
      }
    )
  }
}

