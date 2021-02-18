resource "aws_vpc_peering_connection" "stub_ucfs" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws_ingestion.outputs.stub_ucfs_vpc.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "stub_ucfs_prometheus" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_ingestion.outputs.route_table.stub_ucfs_id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.stub_ucfs[0].id
}

resource "aws_route" "prometheus_stub_ucfs" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = data.terraform_remote_state.aws_ingestion.outputs.stub_ucfs_vpc.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.stub_ucfs[0].id
}

resource "aws_security_group_rule" "stub_ucfs_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access stub ucfs ec2 node metrics"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = data.terraform_remote_state.aws_ingestion.outputs.stub_ucfs_vpc.interface_vpce_sg_id
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_stub_ucfs" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access stub ucfs ec2 node metrics"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = data.terraform_remote_state.aws_ingestion.outputs.stub_ucfs_vpc.interface_vpce_sg_id
}
