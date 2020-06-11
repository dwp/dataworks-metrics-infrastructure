resource "aws_route" "route" {
  count                     = length(data.terraform_remote_state.aws_concourse.outputs.route_tables)
  route_table_id            = data.terraform_remote_state.aws_concourse.outputs.route_tables[count.index].id
  destination_cidr_block    = local.cidr_block[local.environment].mon-master-vpc
  vpc_peering_connection_id = module.vpc.outputs.prometheus_pcx
}

resource "aws_security_group_rule" "web_lb_in_metrics" {
  description       = "inbound traffic to web nodes metrics port"
  from_port         = 9090
  protocol          = "tcp"
  security_group_id = data.terraform_remote_state.aws_concourse.outputs.concourse_web_sg
  to_port           = 9090
  type              = "ingress"
  cidr_blocks       = [local.cidr_block[local.environment].mon-master-vpc]
}