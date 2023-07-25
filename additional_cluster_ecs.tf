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
  image_id      = var.dw_al2_ecs_ami_id
  instance_type = var.additional_metrics_ecs_cluster_ec2_size[local.environment]

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [aws_security_group.metrics_cluster.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
  }

  user_data = base64encode(templatefile(
    "userdata.tpl",
    {
      cluster_name                                     = local.cluster_name # Referencing the cluster resource causes a circular dependency
      instance_role                                    = aws_iam_instance_profile.metrics_cluster.name
      region                                           = data.aws_region.current.name
      folder                                           = "/mnt/config"
      mnt_bucket                                       = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
      name                                             = local.additional_metrics_ecs_friendly_name
      proxy_port                                       = var.proxy_port
      proxy_host                                       = local.internet_proxy.host
      hcs_environment                                  = local.hcs_environment[local.environment]
      s3_scripts_bucket                                = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
      s3_script_logrotate                              = aws_s3_object.metrics_logrotate_script.id
      s3_script_cloudwatch_shell                       = aws_s3_object.metrics_cloudwatch_script.id
      s3_script_logging_shell                          = aws_s3_object.metrics_logging_script.id
      s3_script_config_hcs_shell                       = aws_s3_object.metrics_config_hcs_script.id
      cwa_namespace                                    = local.cw_additional_metrics_server_agent_namespace
      cwa_log_group_name                               = "${local.cw_additional_metrics_server_agent_namespace}-${local.environment}"
      cwa_metrics_collection_interval                  = local.cw_agent_metrics_collection_interval
      cwa_cpu_metrics_collection_interval              = local.cw_agent_cpu_metrics_collection_interval
      cwa_disk_measurement_metrics_collection_interval = local.cw_agent_disk_measurement_metrics_collection_interval
      cwa_disk_io_metrics_collection_interval          = local.cw_agent_disk_io_metrics_collection_interval
      cwa_mem_metrics_collection_interval              = local.cw_agent_mem_metrics_collection_interval
      cwa_netstat_metrics_collection_interval          = local.cw_agent_netstat_metrics_collection_interval
      install_tenable                                  = local.tenable_install[local.environment]
      install_trend                                    = local.trend_install[local.environment]
      install_tanium                                   = local.tanium_install[local.environment]
      tanium_server_1                                  = aws_vpc_endpoint.tanium_service.dns_entry[0].dns_name
      tanium_server_2                                  = local.tanium2
      tanium_env                                       = local.tanium_env[local.environment]
      tanium_port                                      = var.tanium_port_1
      tanium_log_level                                 = local.tanium_log_level[local.environment]
      tenant                                           = local.tenant
      tenantid                                         = local.tenantid
      token                                            = local.token
      policyid                                         = local.policy_id[local.environment]
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
    device_name = "/dev/sda1"

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
  image_id      = var.dw_al2_ecs_ami_id
  instance_type = var.additional_metrics_ecs_cluster_ec2_size[local.environment]

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [aws_security_group.metrics_cluster.id, aws_security_group.monitoring_common[local.secondary_role_index].id]
  }

  user_data = base64encode(templatefile("userdata.tpl",
    {
      cluster_name                                     = local.cluster_name # Referencing the cluster resource causes a circular dependency
      instance_role                                    = aws_iam_instance_profile.metrics_cluster.name
      region                                           = data.aws_region.current.name
      folder                                           = "/mnt/config"
      mnt_bucket                                       = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
      name                                             = local.additional_metrics_ecs_friendly_name
      proxy_port                                       = var.proxy_port
      proxy_host                                       = local.internet_proxy.host
      hcs_environment                                  = local.hcs_environment[local.environment]
      s3_scripts_bucket                                = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id
      s3_script_logrotate                              = aws_s3_object.metrics_logrotate_script.id
      s3_script_cloudwatch_shell                       = aws_s3_object.metrics_cloudwatch_script.id
      s3_script_logging_shell                          = aws_s3_object.metrics_logging_script.id
      s3_script_config_hcs_shell                       = aws_s3_object.metrics_config_hcs_script.id
      cwa_namespace                                    = local.cw_additional_metrics_server_agent_namespace
      cwa_log_group_name                               = "${local.cw_additional_metrics_server_agent_namespace}-${local.environment}"
      cwa_metrics_collection_interval                  = local.cw_agent_metrics_collection_interval
      cwa_cpu_metrics_collection_interval              = local.cw_agent_cpu_metrics_collection_interval
      cwa_disk_measurement_metrics_collection_interval = local.cw_agent_disk_measurement_metrics_collection_interval
      cwa_disk_io_metrics_collection_interval          = local.cw_agent_disk_io_metrics_collection_interval
      cwa_mem_metrics_collection_interval              = local.cw_agent_mem_metrics_collection_interval
      cwa_netstat_metrics_collection_interval          = local.cw_agent_netstat_metrics_collection_interval
      install_tenable                                  = local.tenable_install[local.environment]
      install_trend                                    = local.trend_install[local.environment]
      install_tanium                                   = local.tanium_install[local.environment]
      tanium_server_1                                  = aws_vpc_endpoint.tanium_service[0].dns_entry[0].dns_name
      tanium_server_2                                  = local.tanium2
      tanium_env                                       = local.tanium_env[local.environment]
      tanium_port                                      = var.tanium_port_1
      tanium_log_level                                 = local.tanium_log_level[local.environment]
      tenant                                           = local.tenant
      tenantid                                         = local.tenantid
      token                                            = local.token
      policyid                                         = local.policy_id[local.environment]
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
    device_name = "/dev/sda1"

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
