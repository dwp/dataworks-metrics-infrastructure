resource "aws_efs_file_system" "prometheus" {
  tags = merge(local.tags, { Name = "prometheus_efs" })
}

resource "aws_efs_mount_target" "prometheus" {
  count           = length(module.vpc.outputs.private_subnets[local.secondary_role_index])
  file_system_id  = aws_efs_file_system.prometheus.id
  subnet_id       = module.vpc.outputs.private_subnets[local.secondary_role_index][count.index]
  security_groups = [aws_security_group.prometheus_efs.id]
}

resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.prometheus.id

  root_directory {
    path = "/prometheus"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 600
    }
  }

  posix_user {
    uid = 0
    gid = 0
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_security_group" "prometheus_efs" {
  name        = "prometheus_efs"
  description = "Rules necesary for accessing EFS"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "prometheus_efs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_allow_ingress_prometheus" {
  description              = "Allow prometheus to access efs mount target"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus_efs.id
  to_port                  = 2049
  type                     = "ingress"
  source_security_group_id = aws_security_group.prometheus.id
}


resource "aws_efs_file_system" "outofband" {
  count = local.is_management_env ? 1 : 0
  tags  = merge(local.tags, { Name = "outofband_efs" })
}

resource "aws_efs_mount_target" "outofband" {
  count           = local.is_management_env ? length(module.vpc.outputs.private_subnets[local.primary_role_index]) : 0
  file_system_id  = aws_efs_file_system.outofband[local.primary_role_index].id
  subnet_id       = module.vpc.outputs.private_subnets[local.primary_role_index][count.index]
  security_groups = [aws_security_group.outofband_efs[local.primary_role_index].id]
}

resource "aws_efs_access_point" "outofband" {
  count          = local.is_management_env ? 1 : 0
  file_system_id = aws_efs_file_system.outofband[local.primary_role_index].id

  root_directory {
    path = "/prometheus"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 600
    }
  }

  posix_user {
    uid = 0
    gid = 0
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_security_group" "outofband_efs" {
  count       = local.is_management_env ? 1 : 0
  name        = "outofband_efs"
  description = "Rules necesary for accessing EFS"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "outofband_efs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_allow_ingress_outofband" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus to access efs mount target"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.outofband_efs[local.primary_role_index].id
  to_port                  = 2049
  type                     = "ingress"
  source_security_group_id = aws_security_group.outofband[local.primary_role_index].id
}













resource "aws_efs_file_system" "prometheus_new" {
  tags = merge(local.tags, { Name = "prometheus_efs_new" })
}

resource "aws_efs_mount_target" "prometheus_new" {
  count           = length(module.vpc.outputs.private_subnets[local.secondary_role_index])
  file_system_id  = aws_efs_file_system.prometheus_new.id
  subnet_id       = module.vpc.outputs.private_subnets[local.secondary_role_index][count.index]
  security_groups = [aws_security_group.prometheus_efs_new.id]
}

resource "aws_efs_access_point" "prometheus_new" {
  file_system_id = aws_efs_file_system.prometheus_new.id

  root_directory {
    path = "/prometheus_new"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 600
    }
  }

  posix_user {
    uid = 0
    gid = 0
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_security_group" "prometheus_efs_new" {
  name        = "prometheus_efs_new"
  description = "Rules necesary for accessing EFS"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "prometheus_efs_new" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_allow_ingress_prometheus_new" {
  description              = "Allow prometheus to access efs mount target"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus_efs_new.id
  to_port                  = 2049
  type                     = "ingress"
  source_security_group_id = aws_security_group.prometheus_efs_new.id
}
