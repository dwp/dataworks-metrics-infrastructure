resource "aws_vpc_peering_connection" "adg" {
  count       = local.is_management_env ? 0 : 1
  peer_vpc_id = data.terraform_remote_state.aws_internal_compute.outputs.vpc.vpc.vpc.id
  vpc_id      = module.vpc.outputs.vpcs[local.secondary_role_index].id
  auto_accept = true
  tags        = merge(local.tags, { Name = var.name })
}

resource "aws_route" "adg_prometheus_secondary" {
  count                     = local.is_management_env ? 0 : 1
  route_table_id            = data.terraform_remote_state.aws_internal_compute.outputs.route_table_ids.adg
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.adg[0].id
}

resource "aws_route" "prometheus_secondary_adg" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block_internal_compute_vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.adg[0].id
}

resource "aws_security_group_rule" "adg_allow_ingress_prometheus" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg metrics"
  from_port                = var.prometheus_port
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
  to_port                  = var.prometheus_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "prometheus_allow_egress_adg" {
  count                    = local.is_management_env ? 0 : 1
  description              = "Allow prometheus ${var.secondary} to access adg metrics"
  from_port                = var.prometheus_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus.id
  to_port                  = var.prometheus_port
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.aws_analytical_dataset_generation.outputs.adg_common_sg.id
}
