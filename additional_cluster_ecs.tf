resource "aws_ecs_capacity_provider" "additional_metrics_cluster" {
  name = local.additional_metrics_friendly_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.additional_metrics_cluster.arn
    managed_termination_protection = "DISABLED"

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
      Name = local.additional_metrics_friendly_name
    }
  )
}

resource "aws_autoscaling_group" "additional_metrics_cluster" {
  name                      = local.additional_metrics_friendly_name
  min_size                  = var.additional_cluster_desired_capacity[local.environment]
  desired_capacity          = var.additional_cluster_desired_capacity[local.environment]
  max_size                  = var.additional_metrics_ecs_cluster_asg_max[local.environment]
  protect_from_scale_in     = false
  health_check_grace_period = 600
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = module.vpc.outputs.private_subnets[local.secondary_role_index]

  launch_template {
    id      = aws_launch_template.additional_metrics_cluster.id
    version = aws_launch_template.additional_metrics_cluster.latest_version
  }

  lifecycle {
    create_before_destroy = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
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

resource "aws_launch_template" "additional_metrics_cluster" {
  name          = local.additional_metrics_friendly_name
  image_id      = var.ecs_hardened_ami_id
  instance_type = var.additional_metrics_ecs_cluster_ec2_size[local.environment]

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [aws_security_group.metrics_cluster.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
  }

  user_data = base64encode(templatefile(
    "userdata.tpl",
    {
      cluster_name  = local.cluster_name # Referencing the cluster resource causes a circular dependency
      instance_role = aws_iam_instance_profile.metrics_cluster.name
      region        = data.aws_region.current.name
      folder        = "/mnt/config"
      mnt_bucket    = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
      name          = local.additional_metrics_ecs_friendly_name
      ecs_attributes = jsonencode({
        "instance-type" = "additional"
      })
    }
  ))

  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    arn = aws_iam_instance_profile.metrics_cluster.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = local.ebs_volume_size[local.environment]
      volume_type           = local.ebs_volume_type[local.environment]
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
      Name = local.additional_metrics_friendly_name
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.tags,
      {
        Name                = local.additional_metrics_friendly_name,
        AutoShutdown        = local.metrics_ecs_cluster_asg_autoshutdown[local.environment],
        SSMEnabled          = local.metrics_ecs_cluster_asg_ssmenabled[local.environment],
        Persistence         = "Ignore",
        propagate_at_launch = true,
        InstanceRefresh     = ""
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.tags,
      {
        Name = local.additional_metrics_friendly_name,
      }
    )
  }
}

resource "aws_ecs_capacity_provider" "additional_mgmt_metrics_cluster" {
  count = local.is_management_env ? 1 : 0
  name  = "mgmt-${local.additional_metrics_friendly_name}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.additional_mgmt_metrics_cluster[0].arn
    managed_termination_protection = "DISABLED"

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
      Name = "mgmt-${local.additional_metrics_friendly_name}"
    }
  )
}

resource "aws_autoscaling_group" "additional_mgmt_metrics_cluster" {
  count                     = local.is_management_env ? 1 : 0
  name                      = "mgmt-${local.additional_metrics_friendly_name}"
  min_size                  = var.additional_cluster_desired_capacity[local.environment]
  desired_capacity          = var.additional_cluster_desired_capacity[local.environment]
  max_size                  = var.additional_metrics_ecs_cluster_asg_max[local.environment]
  protect_from_scale_in     = false
  health_check_grace_period = 600
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = module.vpc.outputs.private_subnets[local.secondary_role_index]

  launch_template {
    id      = aws_launch_template.additional_mgmt_metrics_cluster[0].id
    version = aws_launch_template.additional_mgmt_metrics_cluster[0].latest_version
  }

  lifecycle {
    create_before_destroy = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 25
    }
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

resource "aws_launch_template" "additional_mgmt_metrics_cluster" {
  count         = local.is_management_env ? 1 : 0
  name          = "mgmt-${local.additional_metrics_friendly_name}"
  image_id      = var.ecs_hardened_ami_id
  instance_type = var.additional_metrics_ecs_cluster_ec2_size[local.environment]

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [aws_security_group.metrics_cluster.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
  }

  user_data = base64encode(templatefile("userdata.tpl",
    {
      cluster_name  = local.cluster_name # Referencing the cluster resource causes a circular dependency
      instance_role = aws_iam_instance_profile.metrics_cluster.name
      region        = data.aws_region.current.name
      folder        = "/mnt/config"
      mnt_bucket    = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
      name          = local.additional_metrics_ecs_friendly_name
      ecs_attributes = jsonencode({
        "instance-type" = "additional"
      })
    }
  ))

  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    arn = aws_iam_instance_profile.metrics_cluster.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = local.mgmt_ebs_volume_size[local.environment]
      volume_type           = local.mgmt_ebs_volume_type[local.environment]
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
      Name = "mgmt-${local.additional_metrics_friendly_name}"
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.tags,
      {
        Name                = "mgmt-${local.additional_metrics_friendly_name}",
        AutoShutdown        = local.metrics_ecs_cluster_asg_autoshutdown[local.environment],
        SSMEnabled          = local.metrics_ecs_cluster_asg_ssmenabled[local.environment],
        Persistence         = "Ignore",
        propagate_at_launch = true,
        InstanceRefresh     = ""
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.tags,
      {
        Name = "mgmt-${local.additional_metrics_friendly_name}",
      }
    )
  }
}
