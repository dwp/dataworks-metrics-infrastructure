resource "aws_vpc_peering_connection" "analytical_env" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws_analytical_env_infra.outputs.vpc_main.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
}

resource "aws_route" "analytical_env_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_analytical_env_infra.outputs.vpc_main.vpc.main_route_table_id
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.analytical_env[0].id
}

resource "aws_route" "prometheus_secondary_analytical_env" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = data.terraform_remote_state.aws_analytical_env_infra.outputs.vpc_main.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.analytical_env[0].id
}

resource "aws_security_group_rule" "analytical_env_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access analytical_env metrics"
  from_port                = var.prometheus_port
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.aws_analytical_env_infra.outputs.alb_sg.id
  to_port                  = var.prometheus_port
  type                     = "ingress"
  cidr_blocks              = [data.terraform_remote_state.aws_analytical_env_infra.outputs.vpc_main.vpc.cidr_block]
}

resource "aws_security_group_rule" "prometheus_allow_egress_analytical_env" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access analytical_env metrics"
  from_port                = var.prometheus_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus.id
  to_port                  = var.prometheus_port
  type                     = "egress"
  cidr_blocks              = [data.terraform_remote_state.aws_analytical_env_infra.outputs.vpc_main.vpc.cidr_block]
}
