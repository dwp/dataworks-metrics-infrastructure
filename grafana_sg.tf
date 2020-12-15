resource "aws_security_group" "grafana" {
  count       = local.is_management_env ? 1 : 0
  name        = "grafana"
  description = "Rules necesary for pulling container image and accessing other grafana instances"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "grafana" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress_grafana_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow grafana to access thanos query api"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  to_port                  = var.thanos_port_http
  security_group_id        = aws_security_group.grafana[0].id
  source_security_group_id = aws_security_group.thanos_query[0].id
}

resource "aws_security_group_rule" "allow_egress_grafana_thanos_store_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow grafana to access thanos store api"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  to_port                  = var.thanos_port_http
  security_group_id        = aws_security_group.grafana[0].id
  source_security_group_id = aws_security_group.thanos_store[0].id
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_grafana_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access grafanas user interface"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.grafana_port
  to_port                  = var.grafana_port
  security_group_id        = aws_security_group.grafana[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}
