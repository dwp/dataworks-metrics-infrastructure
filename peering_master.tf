provider "aws" {
  version = "~> 2.68.0"
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
  tags          = merge(local.tags, { Name = var.name })
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
  description              = "Allow thanos query node to access prometheus"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = local.is_management_env ? aws_security_group.thanos_query[0].id : data.terraform_remote_state.management_dmi.outputs.thanos_security_group
}

resource "aws_security_group_rule" "prometheus_primary_allow_egress_prometheus_secondary" {
  provider                 = aws.dmi_management
  description              = "Allow thanos query node to access prometheus"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.prometheus_port
  to_port                  = var.prometheus_port
  security_group_id        = local.is_management_env ? aws_security_group.thanos_query[0].id : data.terraform_remote_state.management_dmi.outputs.thanos_security_group
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "thanos_sidecar_allow_ingress_thanos_query" {
  description              = "Allow thanos query node to access thanos sidecar"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = local.is_management_env ? aws_security_group.thanos_query[0].id : data.terraform_remote_state.management_dmi.outputs.thanos_security_group
}

resource "aws_security_group_rule" "thanos_query_allow_egress_thanos_sidecar" {
  provider                 = aws.dmi_management
  description              = "Allow thanos query node to access thanos sidecar"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = local.is_management_env ? aws_security_group.thanos_query[0].id : data.terraform_remote_state.management_dmi.outputs.thanos_security_group
  source_security_group_id = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "thanos_store_allow_ingress_thanos_query" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow thanos query node to access thanos store"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = aws_security_group.thanos_store[0].id
  source_security_group_id = aws_security_group.thanos_query[0].id
}

resource "aws_security_group_rule" "thanos_query_allow_egress_thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow thanos query node to access thanos store"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = aws_security_group.thanos_query[0].id
  source_security_group_id = aws_security_group.thanos_store[0].id
}

resource "aws_security_group_rule" "thanos_query_allow_ingress_thanos_store" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow thanos query node to access thanos store"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = aws_security_group.thanos_query[0].id
  source_security_group_id = aws_security_group.thanos_store[0].id
}

resource "aws_security_group_rule" "thanos_store_allow_egress_thanos_query" {
  count                    = local.is_management_env ? 1 : 0
  description              = "Allow thanos query node to access thanos store"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.thanos_port_grpc
  to_port                  = var.thanos_port_grpc
  security_group_id        = aws_security_group.thanos_store[0].id
  source_security_group_id = aws_security_group.thanos_query[0].id
}
