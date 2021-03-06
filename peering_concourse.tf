resource "aws_vpc_peering_connection" "concourse" {
  count       = local.is_management_env ? 1 : 0
  peer_vpc_id = data.terraform_remote_state.aws_concourse.outputs.aws_vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "concourse_prometheus_secondary" {
  count                     = local.is_management_env ? length(data.terraform_remote_state.aws_concourse.outputs.route_tables) : 0
  route_table_id            = data.terraform_remote_state.aws_concourse.outputs.route_tables[count.index].id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.concourse[0].id
}

resource "aws_route" "prometheus_secondary_concourse" {
  count                     = local.is_management_env ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block_cicd_vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.concourse[0].id
}

resource "aws_security_group_rule" "concourse_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access concourse metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = data.terraform_remote_state.aws_concourse.outputs.concourse_web_sg
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_concourse" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access concourse metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_concourse.outputs.concourse_web_sg
}

resource "aws_security_group_rule" "concourse_web_node_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access concourse web node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_concourse.outputs.concourse_web_sg
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_concourse_web_node" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access concourse web node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_concourse.outputs.concourse_web_sg
}

resource "aws_security_group_rule" "concourse_worker_node_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access concourse worker node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_concourse.outputs.concourse_worker_sg
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_concourse_worker_node" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access concourse worker node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_concourse.outputs.concourse_worker_sg
}
