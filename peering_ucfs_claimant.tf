resource "aws_vpc_peering_connection" "ucfs_claimant" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.ucfs-claimant.outputs.ucfs_claimant_api_vpc.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}
