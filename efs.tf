resource "aws_efs_file_system" "prometheus" {
  count = length(local.roles)
  tags  = merge(local.tags, { Name = "prometheus" })
}

resource "aws_efs_mount_target" "prometheus_primary" {
  count           = local.is_management_env ? length(module.vpc.outputs.private_subnets[local.primary_role_index]) : 0
  file_system_id  = aws_efs_file_system.prometheus[local.primary_role_index].id
  subnet_id       = module.vpc.outputs.private_subnets[local.primary_role_index][count.index]
  security_groups = [aws_security_group.efs[local.primary_role_index].id]
}

resource "aws_efs_mount_target" "prometheus_secondary" {
  count           = length(module.vpc.outputs.private_subnets[local.secondary_role_index])
  file_system_id  = aws_efs_file_system.prometheus[local.secondary_role_index].id
  subnet_id       = module.vpc.outputs.private_subnets[local.secondary_role_index][count.index]
  security_groups = [aws_security_group.efs[local.secondary_role_index].id]
}

resource "aws_efs_access_point" "monitoring" {
  count          = length(local.roles)
  file_system_id = aws_efs_file_system.prometheus[count.index].id
  root_directory {
    path = "/prometheus"
    creation_info {
      owner_gid   = 99
      owner_uid   = 99
      permissions = 644
    }
  }
  posix_user {
    uid = 99
    gid = 99
  }
}

resource "aws_security_group" "efs" {
  count       = length(local.roles)
  name        = "efs-${local.roles[count.index]}"
  description = "Rules necesary for pulling container image and accessing other prometheus instances"
  vpc_id      = module.vpc.outputs.vpcs[count.index].id
  tags        = merge(local.tags, { Name = "prometheus" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_allow_ingress_prometheus" {
  count                    = length(local.roles)
  description              = "Allow prometheus to access efs"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs[count.index].id
  to_port                  = 2049
  type                     = "ingress"
  source_security_group_id = aws_security_group.prometheus[count.index].id
}
