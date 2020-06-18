resource "aws_vpc_peering_connection" "peering" {
  count       = local.roles[0] == "master" ? 1 : 0
  peer_vpc_id = data.terraform_remote_state.aws_concourse.outputs.aws_vpc.id
  vpc_id      = module.vpc.outputs.vpcs[1].id
  auto_accept = true
  tags        = merge(local.tags, { Name = "prometheus_pcx" })
}

resource "aws_route" "concourse_route" {
  count                     = local.roles[0] == "master" ? length(data.terraform_remote_state.aws_concourse.outputs.route_tables) : 0
  route_table_id            = data.terraform_remote_state.aws_concourse.outputs.route_tables[count.index].id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

resource "aws_route" "route" {
  count                     = local.roles[0] == "master" ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[1][count.index]
  destination_cidr_block    = local.cidr_block_cicd_vpc[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.peering[0].id
}

resource "aws_security_group_rule" "web_lb_in_metrics" {
  count                    = local.roles[0] == "master" ? 1 : 0
  description              = "inbound traffic to web nodes metrics port"
  from_port                = 9090
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.aws_concourse.outputs.concourse_web_sg
  to_port                  = 9090
  type                     = "ingress"
  source_security_group_id = aws_security_group.web[1].id
}

resource "aws_security_group_rule" "allow_egress_prometheus" {
  count             = local.roles[0] == "master" ? 1 : 0
  type              = "egress"
  to_port           = 9090
  protocol          = "tcp"
  from_port         = 9090
  security_group_id = aws_security_group.web[1].id
  cidr_blocks       = [local.cidr_block_cicd_vpc[0]]
}
