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
  destination_cidr_block    = data.terraform_remote_state.ucfs-claimant.outputs.ucfs_claimant_api_vpc.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ucfs_claimant[0].id
}
