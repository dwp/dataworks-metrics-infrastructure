resource "aws_route" "route" {
  count                     = length(data.terraform_remote_state.aws_concourse.outputs.route_table)
  route_table_id            = data.terraform_remote_state.aws_concourse.outputs.route_table[count.index].id
  destination_cidr_block    = local.cidr_block[local.environment].mon-master-vpc
  vpc_peering_connection_id = module.vpc.outputs.prometheus_pcx
}