resource "aws_security_group" "thanos_query" {
  count       = local.is_management_env ? 1 : 0
  name        = "thanos-query"
  description = "Rules necesary for pulling container image and accessing other thanos instances"
  vpc_id      = module.vpc.outputs.vpcs[local.primary_role_index].id
  tags        = merge(local.tags, { Name = "thanos-query" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access thanos user interface"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  to_port                  = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_query[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}

resource "aws_security_group_rule" "allow_grafana_ingress_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows grafana to access thanos query api"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  to_port                  = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_query[0].id
  source_security_group_id = aws_security_group.grafana[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_ingress_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access thanos query"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  to_port                  = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_query[0].id
  source_security_group_id = aws_security_group.thanos_ruler[0].id
}
