resource "aws_vpc_peering_connection" "crypto" {
  count       = local.is_management_env ? 1 : 0
  peer_vpc_id = data.terraform_remote_state.aws_crypto.outputs.crypto_vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "crypto_prometheus" {
  count                     = local.is_management_env ? 1 : 0
  route_table_id            = data.terraform_remote_state.aws_crypto.outputs.dks_route_table.id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.crypto[0].id
}

resource "aws_route" "prometheus_crypto" {
  count                     = local.is_management_env ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = data.terraform_remote_state.aws_crypto.outputs.crypto_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.crypto[0].id
}

resource "aws_security_group_rule" "crypto_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access crypto ec2 node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_crypto.outputs.dks_common_sg.id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "crypto_allow_egress_prometheus" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow prometheus ${var.secondary} to access crypto ec2 node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_crypto.outputs.dks_common_sg.id
}
