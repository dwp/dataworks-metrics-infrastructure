resource "aws_vpc_peering_connection" "ucfs_claimant" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.ucfs-claimant.outputs.ucfs_claimant_api_vpc.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "ucfs_claimant_prometheus" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.ucfs-claimant.outputs.ucfs_claimant_api_vpc.vpc.default_route_table_id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.ucfs_claimant[0].id
}

resource "aws_route" "prometheus_ucfs_claimant" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block_ucfs_claimant_vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.ucfs_claimant[0].id
}

resource "aws_security_group_rule" "prometheus_allow_egress_get_award_details_lambda" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access get award details lambda metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.ucfs-claimant.outputs.security_groups.ucfs_claimant_lambda_london
}

resource "aws_security_group_rule" "get_award_details_lambda_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access get award details lambda metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = data.terraform_remote_state.ucfs-claimant.outputs.security_groups.ucfs_claimant_lambda_london
  source_security_group_id = aws_security_group.prometheus.id
}
