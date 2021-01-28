resource "aws_vpc_peering_connection" "crypto" {
  count       = local.is_management_env ? 1 : 0
  peer_vpc_id = data.terraform_remote_state.aws_crypto.outputs.crypto_vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}
