resource "aws_security_group" "alertmanager" {
  count       = local.is_management_env ? 1 : 0
  name        = "alertmanager"
  description = "Rules necesary for pulling container image and accessing other thanos query instance"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "alertmanager" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_alertmanager_egress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.primary_role_index]]
  from_port         = 443
  security_group_id = aws_security_group.alertmanager[0].id
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_alertmanager_port" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access alertmanager user interface"
  type                     = "ingress"
  to_port                  = var.alertmanager_port
  protocol                 = "tcp"
  from_port                = var.alertmanager_port
  security_group_id        = aws_security_group.alertmanager[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_ingress_alertmanager_port" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access alertmanager"
  type                     = "ingress"
  to_port                  = var.alertmanager_port
  protocol                 = "tcp"
  from_port                = var.alertmanager_port
  security_group_id        = aws_security_group.alertmanager[0].id
  source_security_group_id = aws_security_group.thanos_ruler[0].id
}

resource "aws_security_group_rule" "allow_outofband_ingress_alertmanager_port" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows outofband to access alertmanager"
  type                     = "ingress"
  to_port                  = var.alertmanager_port
  protocol                 = "tcp"
  from_port                = var.alertmanager_port
  security_group_id        = aws_security_group.alertmanager[0].id
  source_security_group_id = aws_security_group.outofband[0].id
}
