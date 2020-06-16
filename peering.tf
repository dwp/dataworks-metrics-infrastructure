resource "aws_vpc_peering_connection" "peering" {
  count       = local.roles[0] == "master" ? 1 : 0
  peer_vpc_id = data.terraform_remote_state.aws_concourse.outputs.route_tables[0].vpc_id
  vpc_id      = module.vpc.outputs.vpc_ids[0]
  auto_accept = true
  tags        = merge(local.tags, { Name = "prometheus_pcx" })
}
