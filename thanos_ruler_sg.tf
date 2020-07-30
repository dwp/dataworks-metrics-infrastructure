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

resource "aws_security_group_rule" "allow_thanos_ruler_egress_https" {
  count             = local.is_management_env ? 1 : 0
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  to_port           = var.https_port
  protocol          = "tcp"
  prefix_list_ids   = [module.vpc.outputs.s3_prefix_list_ids[local.primary_role_index]]
  from_port         = var.https_port
  security_group_id = aws_security_group.thanos_ruler[0].id
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_thanos_ruler_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows loadbalancer to access thanos user interface"
  type                     = "ingress"
  to_port                  = var.thanos_port_http
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.monitoring[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_egress_thanos_query_http" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access thanos query"
  type                     = "egress"
  to_port                  = var.thanos_port_http
  protocol                 = "tcp"
  from_port                = var.thanos_port_http
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.thanos_query[0].id
}

resource "aws_security_group_rule" "allow_thanos_ruler_egress_alertmanager" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows thanos ruler to access alertmanager"
  type                     = "egress"
  to_port                  = var.alertmanager_port
  protocol                 = "tcp"
  from_port                = var.alertmanager_port
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.alertmanager[0].id
}

resource "aws_security_group_rule" "allow_outofband_ingress_thanos_ruler" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allows outofband to access thanos ruler"
  type                     = "ingress"
  to_port                  = var.prometheus_port
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  security_group_id        = aws_security_group.thanos_ruler[0].id
  source_security_group_id = aws_security_group.outofband[0].id
}
