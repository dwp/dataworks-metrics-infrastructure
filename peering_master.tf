resource "aws_vpc_peering_connection" "master_slave" {
  count       = local.roles[0] == "master" ? 1 : 0
  peer_vpc_id = module.vpc.outputs.vpc_ids[1]
  vpc_id      = module.vpc.outputs.vpc_ids[0]
  auto_accept = true
  tags        = merge(local.tags, { Name = "master_slave" })
}

resource "aws_route" "slave_route" {
  count                     = local.roles[0] == "master" ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[1][count.index]
  destination_cidr_block    = local.cidr_block[local.environment].mon-master-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.master_slave[0].id
}

resource "aws_route" "master_route" {
  count                     = local.roles[0] == "master" ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[0][count.index]
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.master_slave[0].id
}

resource "aws_security_group_rule" "allow_ingress_master" {
  count                    = local.roles[0] == "master" ? 1 : 0
  description              = "inbound traffic to web nodes metrics port"
  from_port                = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web[1].id
  to_port                  = 9090
  type                     = "ingress"
  source_security_group_id = aws_security_group.web[0].id
}

resource "aws_security_group_rule" "allow_egress_master" {
  count             = local.roles[0] == "master" ? 1 : 0
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.web[0].id
  cidr_blocks       = [local.cidr_block[local.environment].mon-slave-vpc]
}
