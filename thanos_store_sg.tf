resource "aws_security_group" "thanos_store" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-store"
  description = "Rules necesary for pulling container image and accessing other thanos instances"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "thanos-store" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "thanos_store_efs" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-store-efs"
  description = "Rules necesary for allowing thanos-store to use EFS"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "thanos-store-efs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress_from_thanos_store_to_efs" {
  count                    = local.is_management_env ? 1 : 0
  description              = "egress_from_thanos_store_to_efs"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  security_group_id        = aws_security_group.thanos_store[0].id
  source_security_group_id = aws_security_group.thanos_store_efs[0].id
}

resource "aws_security_group_rule" "egress_from_efs_to_thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  description              = "egress_from_efs_to_thanos_store"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  security_group_id        = aws_security_group.thanos_store_efs[0].id
  source_security_group_id = aws_security_group.thanos_store[0].id
}

resource "aws_security_group_rule" "ingress_in_efs_from_thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  description              = "ingress_in_efs_from_thanos_store"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  security_group_id        = aws_security_group.thanos_store_efs[0].id
  source_security_group_id = aws_security_group.thanos_store[0].id
}

resource "aws_security_group_rule" "ingress_in_thanos_store_from_efs" {
  count                    = local.is_management_env ? 1 : 0
  description              = "ingress_in_thanos_store_from_efs"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  security_group_id        = aws_security_group.thanos_store[0].id
  source_security_group_id = aws_security_group.thanos_store_efs[0].id
}

resource "aws_security_group_rule" "ingress_inside_thanos_store_from_efs" {
  count             = local.is_management_env ? 1 : 0
  description       = "ingress_inside_thanos_store_from_efs"
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.thanos_store_efs[0].id
  self              = true
}

resource "aws_security_group_rule" "egress_inside_thanos_store_from_efs" {
  count             = local.is_management_env ? 1 : 0
  description       = "egress_inside_thanos_store_from_efs"
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.thanos_store_efs[0].id
  self              = true
}
