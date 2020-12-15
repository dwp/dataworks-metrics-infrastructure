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

resource "aws_security_group_rule" "allow_loadbalancer_ingress_thanos_store_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access thanos user interface"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10902
  to_port                  = 10902
  security_group_id        = aws_security_group.thanos_store[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}

resource "aws_security_group_rule" "thanos_store_allow_ingress_thanos_query" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow thanos query node to access thanos store"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = aws_security_group.thanos_store[0].id
  source_security_group_id = aws_security_group.thanos_query[0].id
}

resource "aws_security_group_rule" "thanos_query_allow_egress_thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow thanos query node to access thanos sidecar"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = aws_security_group.thanos_query[0].id
  source_security_group_id = aws_security_group.thanos_store[0].id
}
