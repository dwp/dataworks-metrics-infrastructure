provider "aws" {
  version = "~> 2.67.0"
  region  = var.region
  alias   = "dmi_management"

  assume_role {
    role_arn = "arn:aws:iam::${lookup(local.account, lookup(local.slave_peerings, local.environment))}:role/${var.assume_role}"
  }
}

resource "aws_vpc_peering_connection" "prometheus" {
  peer_owner_id = lookup(local.account, lookup(local.slave_peerings, local.environment))
  peer_vpc_id   = local.is_management_env ? module.vpc.outputs.vpcs[0].id : data.terraform_remote_state.management_dmi.outputs.vpcs[0].id
  vpc_id        = module.vpc.outputs.vpcs[local.secondary_role_index].id
}

resource "aws_route" "management_prometheus_secondary_prometheus_primary" {
  count                     = local.is_management_env ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = local.cidr_block_mon_master_vpc[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.prometheus.id
}

resource "aws_route" "non_management_prometheus_secondary_prometheus_primary" {
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = module.vpc.outputs.private_route_tables[local.secondary_role_index][count.index]
  destination_cidr_block    = data.terraform_remote_state.management_dmi.outputs.vpcs[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.prometheus.id
}

resource "aws_route" "management_prometheus_primary_prometheus_secondary" {
  count                     = local.is_management_env ? local.zone_count : 0
  route_table_id            = module.vpc.outputs.private_route_tables[0][count.index]
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.prometheus.id
}

resource "aws_route" "non_management_prometheus_primary_prometheus_secondary" {
  provider                  = aws.dmi_management
  count                     = local.is_management_env ? 0 : local.zone_count
  route_table_id            = data.terraform_remote_state.management_dmi.outputs.private_route_tables[0][count.index]
  destination_cidr_block    = local.cidr_block[local.environment].mon-slave-vpc
  vpc_peering_connection_id = aws_vpc_peering_connection.prometheus.id
}

resource "aws_security_group_rule" "prometheus_secondary_allow_ingress_prometheus_primary" {
  description       = "Allow prometheus ${var.primary} to access prometheus ${var.secondary}"
  from_port         = var.prom_port
  protocol          = "tcp"
  security_group_id = aws_security_group.prometheus[local.secondary_role_index].id
  to_port           = var.prom_port
  type              = "ingress"
  cidr_blocks       = ["${lookup(local.cidr_block, lookup(local.slave_peerings, local.environment)).mon-master-vpc}"]
}

resource "aws_security_group_rule" "prometheus_primary_allow_egress_prometheus_secondary" {
  provider          = aws.dmi_management
  description       = "Allow prometheus ${var.primary} to access prometheus ${var.secondary}"
  type              = "egress"
  to_port           = var.prom_port
  protocol          = "tcp"
  from_port         = var.prom_port
  security_group_id = local.is_management_env ? aws_security_group.prometheus.id : data.terraform_remote_state.management_dmi.outputs.prometheus_security_group.id
  cidr_blocks       = [local.cidr_block[local.environment].mon-slave-vpc]
}
