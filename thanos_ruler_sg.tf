resource "aws_security_group" "thanos_ruler" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-ruler"
  description = "Rules necesary for pulling container image and accessing other thanos instances"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "thanos-ruler" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_thanos_ruler_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access thanos user interface"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  to_port                  = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_egress_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access thanos query"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  to_port                  = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.thanos_query[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_egress_alertmanager" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access alertmanager"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.alertmanager_port
  to_port                  = var.alertmanager_port
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.alertmanager[0].id
}

resource "aws_security_group_rule" "allow_outofband_ingress_thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows outofband to access thanos ruler"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.outofband[0].id
}
