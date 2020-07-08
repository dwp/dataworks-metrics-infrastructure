resource "aws_efs_file_system" "prometheus" {
  tags = merge(local.tags, { Name = "prometheus" })
}

resource "aws_efs_mount_target" "prometheus" {
  count           = length(module.vpc.outputs.private_subnets[local.secondary_role_index])
  file_system_id  = aws_efs_file_system.prometheus.id
  subnet_id       = module.vpc.outputs.private_subnets[local.secondary_role_index][count.index]
  security_groups = [aws_security_group.efs.id]
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
}

resource "aws_security_group" "efs" {
  name        = "efs"
  description = "Rules necesary for accessing EFS"
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  tags        = merge(local.tags, { Name = "efs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_allow_ingress_prometheus" {
  description              = "Allow prometheus to access efs"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  to_port                  = 2049
  type                     = "ingress"
  source_security_group_id = aws_security_group.prometheus.id
}
