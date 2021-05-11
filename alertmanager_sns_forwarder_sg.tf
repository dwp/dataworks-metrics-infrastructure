resource "aws_security_group" "alertmanager_sns_forwarder" {
  count       = local.is_management_env ? 1 : 0
  name        = "alertmanager_sns_forwarder"
  description = "Rules necesary for pulling container image and accessing other thanos query instance"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "alertmanager_sns_forwarder" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_thanos_ruler_ingress_alertmanager_sns_forwarder_port" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access alertmanager_sns_forwarder"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9087
  to_port                  = 9087
  security_group_id        = aws_security_group.alertmanager_sns_forwarder[0].id
  source_security_group_id = aws_security_group.alertmanager[0].id
}
