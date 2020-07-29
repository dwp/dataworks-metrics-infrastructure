resource "aws_security_group" "outofband" {
  count       = local.is_management_env ? 1 : 0
  name        = "outofband"
  description = "Rules necesary for pulling container image and accessing other thanos ruler instance"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "outofband" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_outofband_egress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.primary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.outofband[local.primary_role_index].id
}

resource "aws_security_group_rule" "outofband_allow_egress_efs" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow outofband to access efs mount target"
  from_port                = 2049
  protocol                 = "tcp"
  to_port                  = 2049
  type                     = "egress"
  security_group_id        = aws_security_group.outofband[local.primary_role_index].id
  source_security_group_id = aws_security_group.outofband_efs[local.primary_role_index].id
}

resource "aws_security_group_rule" "outofband_allow_egress_thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow outofband to access thanos ruler"
  from_port                = var.thanos_port_http
  protocol                 = "tcp"
  to_port                  = var.thanos_port_http
  type                     = "egress"
  security_group_id        = aws_security_group.outofband[local.primary_role_index].id
  source_security_group_id = aws_security_group.thanos_ruler[0].id
}

resource "aws_security_group_rule" "outofband_allow_egress_alertmanager" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow outofband to access alertmanager"
  from_port                = var.alertmanager_port
  protocol                 = "tcp"
  to_port                  = var.alertmanager_port
  type                     = "egress"
  security_group_id        = aws_security_group.outofband[local.primary_role_index].id
  source_security_group_id = aws_security_group.alertmanager[0].id
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_outofband_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access outofbands user interface"
  type                     = "ingress"
  to_port                  = var.prometheus_port
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  security_group_id        = aws_security_group.outofband[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}
